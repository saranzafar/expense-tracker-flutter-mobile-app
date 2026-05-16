import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../data/providers.dart';
import 'backup_prefs.dart';
import 'drive_client.dart';
import 'google_auth.dart';

enum BackupOutcome { success, notSignedIn, networkError, alreadyRunning, quotaExceeded, unknownError }
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
      await staging.rename(live.path);

      // Force provider to re-create the DB next read.
      _ref.invalidate(databaseProvider);
      return const RestoreResult(RestoreOutcome.success);
    } on SocketException catch (e) {
      return RestoreResult(RestoreOutcome.networkError, e.message);
    } catch (e) {
      return RestoreResult(RestoreOutcome.unknownError, e.toString());
    }
  }

  Future<void> autoBackupIfDue() async {
    final prefs = _ref.read(backupPrefsProvider);
    if (!prefs.enabled) return;
    final account = _ref.read(googleAuthProvider);
    if (account == null) return;
    final last = prefs.lastBackupAt;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(hours: 24)) {
      return;
    }
    if (prefs.wifiOnly) {
      final list = await Connectivity().checkConnectivity();
      if (!list.contains(ConnectivityResult.wifi)) return;
    }
    try {
      await backupNow();
    } catch (_) {
      // never crash app from auto-backup
    }
  }
}

final backupRepoProvider = Provider<BackupRepo>((ref) => BackupRepo(ref));
