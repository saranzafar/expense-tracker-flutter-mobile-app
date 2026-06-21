import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../data/providers.dart';
import '../../../data/settings_repo.dart';
import 'backup_prefs.dart';
import 'drive_client.dart';
import 'google_auth.dart';

enum BackupOutcome { success, notSignedIn, networkError, alreadyRunning, quotaExceeded, remoteNewer, unknownError }
enum RestoreOutcome { success, notSignedIn, notFound, schemaTooNew, networkError, unknownError }

class BackupResult {
  final BackupOutcome outcome;
  final String? message;
  const BackupResult(this.outcome, [this.message]);
}

class RestoreResult {
  final RestoreOutcome outcome;
  final String? message;
  const RestoreResult(this.outcome, [this.message]);
}

class BackupRepo {
  BackupRepo(this._ref);
  final Ref _ref;
  Future<BackupResult>? _inFlight;

  Future<RemoteBackupInfo?> findLatest() async {
    final account = _ref.read(googleAuthProvider);
    if (account == null) return null;
    try {
      return await DriveClient(account).findBackup();
    } catch (_) {
      return null;
    }
  }

  Future<BackupResult> backupNow() {
    return _inFlight ??= _doBackup().whenComplete(() => _inFlight = null);
  }

  Future<BackupResult> _doBackup() async {
    final account = _ref.read(googleAuthProvider);
    if (account == null) return const BackupResult(BackupOutcome.notSignedIn);

    final db = _ref.read(databaseProvider);
    final dir = await getApplicationDocumentsDirectory();
    final snapshot = File(p.join(dir.path, 'xpense-snapshot.sqlite'));
    if (snapshot.existsSync()) {
      try {
        snapshot.deleteSync();
      } catch (_) {}
    }

    try {
      await db.snapshotTo(snapshot.path);
      final bytes = await snapshot.readAsBytes();
      final recordCount = await db.countRecords();
      final pkg = await PackageInfo.fromPlatform();
      final metadata = BackupMetadata(
        schemaVersion: db.schemaVersion,
        createdAt: DateTime.now(),
        recordCount: recordCount,
        appVersion: pkg.version,
        settings: _snapshotSettings(),
      );
      await DriveClient(account).uploadOrUpdate(bytes, metadata);
      await _ref.read(backupPrefsProvider.notifier).markBackupNow();
      return const BackupResult(BackupOutcome.success);
    } on SocketException catch (e) {
      return BackupResult(BackupOutcome.networkError, e.message);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('storageQuotaExceeded')) {
        return BackupResult(BackupOutcome.quotaExceeded, msg);
      }
      return BackupResult(BackupOutcome.unknownError, msg);
    } finally {
      try {
        if (snapshot.existsSync()) snapshot.deleteSync();
      } catch (_) {}
    }
  }

  Future<RestoreResult> restoreFromDrive() async {
    final account = _ref.read(googleAuthProvider);
    if (account == null) {
      return const RestoreResult(RestoreOutcome.notSignedIn);
    }
    try {
      final client = DriveClient(account);
      final info = await client.findBackup();
      if (info == null) {
        return const RestoreResult(RestoreOutcome.notFound);
      }
      final db = _ref.read(databaseProvider);
      final localSchema = db.schemaVersion;
      final remoteSchema = info.metadata?.schemaVersion ?? localSchema;
      if (remoteSchema > localSchema) {
        return const RestoreResult(RestoreOutcome.schemaTooNew,
            'Backup was created with a newer app version.');
      }

      final bytes = await client.download(info.fileId);
      final dir = await getApplicationDocumentsDirectory();
      final staging = File(p.join(dir.path, 'xpense-restore.sqlite'));
      await staging.writeAsBytes(bytes, flush: true);

      // Close current DB, then atomically swap.
      await db.close();
      final live = File(p.join(dir.path, 'xpense.sqlite'));
      if (live.existsSync()) {
        try {
          live.deleteSync();
        } catch (_) {}
      }
      // Drop the old write-ahead-log siblings too. If left behind, SQLite can
      // replay a stale WAL on top of the freshly restored file and corrupt it.
      for (final ext in const ['-wal', '-shm']) {
        final sibling = File('${live.path}$ext');
        if (sibling.existsSync()) {
          try {
            sibling.deleteSync();
          } catch (_) {}
        }
      }
      await staging.rename(live.path);

      // Bring back the user's settings (currency, theme, …) from the backup.
      await _applySettings(info.metadata?.settings);

      // Re-create the DB and rebuild every provider that reads from it so the
      // restored data shows immediately — no app restart needed.
      _ref.invalidate(databaseProvider);
      await _ref.read(backupPrefsProvider.notifier).setRemoteNewer(false);
      return const RestoreResult(RestoreOutcome.success);
    } on SocketException catch (e) {
      return RestoreResult(RestoreOutcome.networkError, e.message);
    } catch (e) {
      return RestoreResult(RestoreOutcome.unknownError, e.toString());
    }
  }

  /// Current app settings, serialized for inclusion in a backup.
  Map<String, dynamic> _snapshotSettings() => {
        'currencyCode': _ref.read(currencyProvider).code,
        'themeMode': themeModeToString(_ref.read(themeModeProvider)),
        'displayName': _ref.read(displayNameProvider),
        'balanceHidden': _ref.read(balanceHiddenProvider),
      };

  /// Applies settings from a restored backup, updating both persistence and
  /// the live providers so the UI reflects them right away.
  Future<void> _applySettings(Map<String, dynamic>? s) async {
    if (s == null) return;
    final code = s['currencyCode'];
    if (code is String) await _ref.read(currencyProvider.notifier).set(code);
    final theme = s['themeMode'];
    if (theme is String) {
      await _ref
          .read(themeModeProvider.notifier)
          .set(themeModeFromString(theme));
    }
    final name = s['displayName'];
    if (name is String) await _ref.read(displayNameProvider.notifier).set(name);
    final hidden = s['balanceHidden'];
    if (hidden is bool) {
      await _ref.read(balanceHiddenProvider.notifier).set(hidden);
    }
  }

  /// Backs up automatically when conditions are met. [minInterval] throttles
  /// how stale the last backup must be — 24h for launch/connectivity triggers,
  /// shorter for the app-backgrounded trigger so recent edits aren't lost.
  Future<BackupResult?> autoBackupIfDue({
    Duration minInterval = const Duration(hours: 24),
  }) async {
    final prefs = _ref.read(backupPrefsProvider);
    if (!prefs.enabled) return null;
    final account = _ref.read(googleAuthProvider);
    if (account == null) return null;
    final last = prefs.lastBackupAt;
    if (last != null && DateTime.now().difference(last) < minInterval) {
      return null;
    }
    if (prefs.wifiOnly) {
      final list = await Connectivity().checkConnectivity();
      if (!list.contains(ConnectivityResult.wifi)) return null;
    }

    // Conflict guard: never let an automatic backup clobber a cloud copy that
    // looks newer than what this device last uploaded (e.g. another device).
    // The user is prompted to restore instead.
    final remote = await findLatest();
    if (remote != null) {
      final remoteCreated = remote.metadata?.createdAt;
      final bool remoteIsNewer;
      if (last != null) {
        // Cloud modified after our last upload → another device got ahead.
        remoteIsNewer = remoteCreated != null && remoteCreated.isAfter(last);
      } else {
        // Never backed up from this device: only defer to the cloud when we
        // have nothing to lose locally (empty DB). Otherwise upload our data.
        remoteIsNewer = await _ref.read(databaseProvider).isEmpty();
      }
      if (remoteIsNewer) {
        await _ref.read(backupPrefsProvider.notifier).setRemoteNewer(true);
        return const BackupResult(BackupOutcome.remoteNewer);
      }
    }

    try {
      final result = await backupNow();
      // Record non-transient failures so the UI can warn the user. Network
      // errors are transient and intentionally ignored.
      if (result.outcome != BackupOutcome.success &&
          result.outcome != BackupOutcome.networkError) {
        await _ref
            .read(backupPrefsProvider.notifier)
            .setLastError(_backupErrorText(result.outcome));
      }
      return result;
    } catch (e) {
      await _ref
          .read(backupPrefsProvider.notifier)
          .setLastError('Backup failed: $e');
      return null;
    }
  }

  String _backupErrorText(BackupOutcome o) {
    switch (o) {
      case BackupOutcome.quotaExceeded:
        return 'Google Drive storage is full.';
      case BackupOutcome.notSignedIn:
        return 'Signed out — reconnect to keep backing up.';
      default:
        return 'Last automatic backup failed.';
    }
  }
}

final backupRepoProvider = Provider<BackupRepo>((ref) => BackupRepo(ref));
