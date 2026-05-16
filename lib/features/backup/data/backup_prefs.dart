import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kEnabled = 'backup_enabled';
const _kWifiOnly = 'backup_wifi_only';
const _kLastBackupAt = 'last_backup_at';
const _kPendingRestoreChecked = 'pending_restore_checked';

class BackupPrefs {
  final bool enabled;
  final bool wifiOnly;
  final int lastBackupAtMs; // 0 = never
  final bool pendingRestoreChecked;

  const BackupPrefs({
    required this.enabled,
    required this.wifiOnly,
    required this.lastBackupAtMs,
    required this.pendingRestoreChecked,
  });

  static const defaults = BackupPrefs(
    enabled: false,
    wifiOnly: true,
    lastBackupAtMs: 0,
    pendingRestoreChecked: false,
  );

  DateTime? get lastBackupAt => lastBackupAtMs == 0
      ? null
      : DateTime.fromMillisecondsSinceEpoch(lastBackupAtMs);

  BackupPrefs copyWith({
    bool? enabled,
    bool? wifiOnly,
    int? lastBackupAtMs,
    bool? pendingRestoreChecked,
  }) =>
      BackupPrefs(
        enabled: enabled ?? this.enabled,
        wifiOnly: wifiOnly ?? this.wifiOnly,
        lastBackupAtMs: lastBackupAtMs ?? this.lastBackupAtMs,
        pendingRestoreChecked:
            pendingRestoreChecked ?? this.pendingRestoreChecked,
      );
}

class BackupPrefsRepo {
  Future<BackupPrefs> read() async {
    final p = await SharedPreferences.getInstance();
    return BackupPrefs(
      enabled: p.getBool(_kEnabled) ?? false,
      wifiOnly: p.getBool(_kWifiOnly) ?? true,
      lastBackupAtMs: p.getInt(_kLastBackupAt) ?? 0,
      pendingRestoreChecked: p.getBool(_kPendingRestoreChecked) ?? false,
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
    state = state.copyWith(lastBackupAtMs: now);
    await ref.read(backupPrefsRepoProvider).writeLastBackupAt(now);
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
