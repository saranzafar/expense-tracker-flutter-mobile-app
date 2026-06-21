import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kEnabled = 'backup_enabled';
const _kWifiOnly = 'backup_wifi_only';
const _kLastBackupAt = 'last_backup_at';
const _kPendingRestoreChecked = 'pending_restore_checked';
const _kLastError = 'backup_last_error';
const _kRemoteNewer = 'backup_remote_newer';

class BackupPrefs {
  final bool enabled;
  final bool wifiOnly;
  final int lastBackupAtMs; // 0 = never
  final bool pendingRestoreChecked;

  /// Last auto-backup failure message (non-transient), or null if the last
  /// attempt succeeded. Surfaced on the Backup page so silent failures don't
  /// leave the user thinking they're protected when they aren't.
  final String? lastError;

  /// True when the cloud backup looks newer than this device's last backup
  /// (e.g. another device backed up more recently). Auto-backup is skipped to
  /// avoid clobbering it; the user is prompted to restore instead.
  final bool remoteNewer;

  const BackupPrefs({
    required this.enabled,
    required this.wifiOnly,
    required this.lastBackupAtMs,
    required this.pendingRestoreChecked,
    this.lastError,
    this.remoteNewer = false,
  });

  static const defaults = BackupPrefs(
    enabled: false,
    wifiOnly: true,
    lastBackupAtMs: 0,
    pendingRestoreChecked: false,
    lastError: null,
    remoteNewer: false,
  );

  DateTime? get lastBackupAt => lastBackupAtMs == 0
      ? null
      : DateTime.fromMillisecondsSinceEpoch(lastBackupAtMs);

  BackupPrefs copyWith({
    bool? enabled,
    bool? wifiOnly,
    int? lastBackupAtMs,
    bool? pendingRestoreChecked,
    // Use sentinels so null can be assigned explicitly (to clear the error).
    Object? lastError = _unset,
    bool? remoteNewer,
  }) =>
      BackupPrefs(
        enabled: enabled ?? this.enabled,
        wifiOnly: wifiOnly ?? this.wifiOnly,
        lastBackupAtMs: lastBackupAtMs ?? this.lastBackupAtMs,
        pendingRestoreChecked:
            pendingRestoreChecked ?? this.pendingRestoreChecked,
        lastError: identical(lastError, _unset)
            ? this.lastError
            : lastError as String?,
        remoteNewer: remoteNewer ?? this.remoteNewer,
      );
}

const _unset = Object();

class BackupPrefsRepo {
  Future<BackupPrefs> read() async {
    final p = await SharedPreferences.getInstance();
    return BackupPrefs(
      enabled: p.getBool(_kEnabled) ?? false,
      wifiOnly: p.getBool(_kWifiOnly) ?? true,
      lastBackupAtMs: p.getInt(_kLastBackupAt) ?? 0,
      pendingRestoreChecked: p.getBool(_kPendingRestoreChecked) ?? false,
      lastError: p.getString(_kLastError),
      remoteNewer: p.getBool(_kRemoteNewer) ?? false,
    );
  }

  Future<void> writeEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnabled, v);
  }

  Future<void> writeWifiOnly(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kWifiOnly, v);
  }

  Future<void> writeLastBackupAt(int ms) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kLastBackupAt, ms);
  }

  Future<void> writePendingRestoreChecked(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kPendingRestoreChecked, v);
  }

  Future<void> writeLastError(String? v) async {
    final p = await SharedPreferences.getInstance();
    if (v == null) {
      await p.remove(_kLastError);
    } else {
      await p.setString(_kLastError, v);
    }
  }

  Future<void> writeRemoteNewer(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kRemoteNewer, v);
  }
}

final backupPrefsRepoProvider =
    Provider<BackupPrefsRepo>((_) => BackupPrefsRepo());

class BackupPrefsNotifier extends Notifier<BackupPrefs> {
  @override
  BackupPrefs build() => BackupPrefs.defaults;

  Future<void> setEnabled(bool v) async {
    state = state.copyWith(enabled: v);
    await ref.read(backupPrefsRepoProvider).writeEnabled(v);
  }

  Future<void> setWifiOnly(bool v) async {
    state = state.copyWith(wifiOnly: v);
    await ref.read(backupPrefsRepoProvider).writeWifiOnly(v);
  }

  Future<void> markBackupNow() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    // A successful backup clears any prior failure / conflict state.
    state = state.copyWith(
        lastBackupAtMs: now, lastError: null, remoteNewer: false);
    final repo = ref.read(backupPrefsRepoProvider);
    await repo.writeLastBackupAt(now);
    await repo.writeLastError(null);
    await repo.writeRemoteNewer(false);
  }

  Future<void> setLastError(String? v) async {
    state = state.copyWith(lastError: v);
    await ref.read(backupPrefsRepoProvider).writeLastError(v);
  }

  Future<void> setRemoteNewer(bool v) async {
    state = state.copyWith(remoteNewer: v);
    await ref.read(backupPrefsRepoProvider).writeRemoteNewer(v);
  }

  Future<void> markPendingRestoreChecked() async {
    state = state.copyWith(pendingRestoreChecked: true);
    await ref
        .read(backupPrefsRepoProvider)
        .writePendingRestoreChecked(true);
  }
}

final backupPrefsProvider =
    NotifierProvider<BackupPrefsNotifier, BackupPrefs>(
        BackupPrefsNotifier.new);
