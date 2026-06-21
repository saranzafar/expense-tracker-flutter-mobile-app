import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/motion.dart';
import '../../../core/theme.dart';
import '../../../data/providers.dart';
import '../../../data/settings_repo.dart';
import '../data/backup_prefs.dart';
import '../data/backup_repo.dart';
import '../data/drive_client.dart';
import '../data/google_auth.dart';

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(googleAuthProvider);
    final prefs = ref.watch(backupPrefsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Backup')),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _SectionLabel('Display name'),
            const SizedBox(height: 8),
            const _DisplayNameCard(),
            const SizedBox(height: 20),
            _SectionLabel('Account'),
            const SizedBox(height: 8),
            _AccountCard(
              account: account,
              busy: _busy,
              onConnect: _onConnect,
              onSignOut: _onSignOut,
            ),
            if (account != null) ...[
              const SizedBox(height: 16),
              _SectionLabel('Backup'),
              const SizedBox(height: 8),
              _StatusCard(prefs: prefs, busy: _busy),
              if (!_busy && (prefs.remoteNewer || prefs.lastError != null)) ...[
                const SizedBox(height: 12),
                _BackupWarning(
                  prefs: prefs,
                  onRestore: _onRestoreManual,
                ),
              ],
              const SizedBox(height: 12),
              _Toggles(prefs: prefs),
              const SizedBox(height: 16),
              _Actions(
                  prefs: prefs,
                  busy: _busy,
                  onBackup: _onBackup,
                  onRestore: _onRestoreManual),
            ],
            const SizedBox(height: 20),
            _SectionLabel('About backup'),
            const SizedBox(height: 8),
            _InfoCard(),
          ],
        ),
      ),
    );
  }

  Future<void> _onConnect() async {
    setState(() => _busy = true);
    try {
      // Set enabled BEFORE sign-in so the auth provider's build() wires up
      // silent sign-in for next launch.
      await ref.read(backupPrefsProvider.notifier).setEnabled(true);
      GoogleSignInAccount? acc;
      try {
        acc = await ref.read(googleAuthProvider.notifier).signIn();
      } on GoogleSignInFailure catch (e) {
        await ref.read(backupPrefsProvider.notifier).setEnabled(false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              duration: const Duration(seconds: 8),
            ),
          );
        }
        return;
      }
      if (acc == null) {
        // user cancelled — roll back the opt-in flag to stay offline-first
        await ref.read(backupPrefsProvider.notifier).setEnabled(false);
        return;
      }
      // After successful sign-in, see if there's a backup AND local DB is
      // empty → offer restore.
      await _maybeOfferRestore();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _maybeOfferRestore() async {
    final prefs = ref.read(backupPrefsProvider);
    if (prefs.pendingRestoreChecked) return;
    final db = ref.read(databaseProvider);
    final isEmpty = await db.isEmpty();
    if (!isEmpty) {
      await ref.read(backupPrefsProvider.notifier).markPendingRestoreChecked();
      return;
    }
    final info = await ref.read(backupRepoProvider).findLatest();
    if (!mounted) return;
    if (info == null) {
      await ref.read(backupPrefsProvider.notifier).markPendingRestoreChecked();
      return;
    }
    final restore = await _showRestoreSheet(info);
    await ref.read(backupPrefsProvider.notifier).markPendingRestoreChecked();
    if (restore == true && mounted) {
      await _runRestore();
    }
  }

  Future<void> _onSignOut() async {
    setState(() => _busy = true);
    try {
      await ref.read(googleAuthProvider.notifier).signOut();
      await ref.read(backupPrefsProvider.notifier).setEnabled(false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onBackup() async {
    setState(() => _busy = true);
    try {
      final r = await ref.read(backupRepoProvider).backupNow();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_backupMessage(r))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onRestoreManual() async {
    final info = await ref.read(backupRepoProvider).findLatest();
    if (!mounted) return;
    if (info == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No backup found in your Drive.')),
      );
      return;
    }
    final ok = await _showRestoreSheet(info);
    if (ok == true) await _runRestore();
  }

  Future<void> _runRestore() async {
    setState(() => _busy = true);
    try {
      final r = await ref.read(backupRepoProvider).restoreFromDrive();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_restoreMessage(r))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _showRestoreSheet(RemoteBackupInfo info) {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => _RestoreSheet(info: info),
    );
  }

  String _backupMessage(BackupResult r) {
    switch (r.outcome) {
      case BackupOutcome.success:
        return 'Backup uploaded ✓';
      case BackupOutcome.notSignedIn:
        return 'Sign in first.';
      case BackupOutcome.networkError:
        return 'No internet. Backup paused.';
      case BackupOutcome.alreadyRunning:
        return 'Backup already in progress.';
      case BackupOutcome.quotaExceeded:
        return 'Drive storage full.';
      case BackupOutcome.remoteNewer:
        return 'Cloud has newer data — restore instead.';
      case BackupOutcome.unknownError:
        return 'Backup failed. ${r.message ?? ''}';
    }
  }

  String _restoreMessage(RestoreResult r) {
    switch (r.outcome) {
      case RestoreOutcome.success:
        return 'Restored ✓';
      case RestoreOutcome.notSignedIn:
        return 'Sign in first.';
      case RestoreOutcome.notFound:
        return 'No backup found in your Drive.';
      case RestoreOutcome.schemaTooNew:
        return 'Backup is from a newer version. Update the app first.';
      case RestoreOutcome.networkError:
        return 'No internet.';
      case RestoreOutcome.unknownError:
        return 'Restore failed. ${r.message ?? ''}';
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Text(text,
          style: AppTextStyles.caption.copyWith(color: context.inkMuted)),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.busy,
    required this.onConnect,
    required this.onSignOut,
  });
  final GoogleSignInAccount? account;
  final bool busy;
  final VoidCallback onConnect;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: context.hairline),
        borderRadius: BorderRadius.circular(20),
      ),
      child: account == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Not connected', style: AppTextStyles.title),
                const SizedBox(height: 4),
                Text(
                    'Sign in to back up your data privately to Google Drive.',
                    style: AppTextStyles.caption
                        .copyWith(color: context.inkMuted)),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.ink,
                  ),
                  onPressed: busy ? null : onConnect,
                  icon: const Icon(Icons.cloud_outlined),
                  label: const Text('Connect Google'),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.greenSoft,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (account!.photoUrl != null)
                      ? Image.network(account!.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                              child: Icon(Icons.person, color: context.ink)))
                      : Center(child: Icon(Icons.person, color: context.ink)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account!.displayName ?? 'Google account',
                          style: AppTextStyles.title
                              .copyWith(color: context.ink)),
                      const SizedBox(height: 2),
                      Text(account!.email,
                          style: AppTextStyles.caption
                              .copyWith(color: context.inkMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: busy ? null : onSignOut,
                  child: Text('Sign out',
                      style: AppTextStyles.caption.copyWith(
                          color: context.ink,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.prefs, required this.busy});
  final BackupPrefs prefs;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final last = prefs.lastBackupAt;
    final title = busy
        ? 'Backing up…'
        : last == null
            ? 'Never backed up yet'
            : 'Last backup · ${_relativeTime(last)}';
    final icon = busy
        ? Icons.cloud_sync_outlined
        : last == null
            ? Icons.cloud_off_outlined
            : Icons.cloud_done_outlined;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: context.hairline),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.greenSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: XSwitcher(
              duration: AppMotion.fast,
              child: Icon(icon,
                  key: ValueKey(icon.codePoint),
                  color: AppColors.ink,
                  size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: XSwitcher(
              duration: AppMotion.fast,
              child: Text(title,
                  key: ValueKey(title),
                  style: AppTextStyles.title.copyWith(color: context.ink)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupWarning extends StatelessWidget {
  const _BackupWarning({required this.prefs, required this.onRestore});
  final BackupPrefs prefs;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    // Conflict (cloud newer) takes priority over a generic failure message.
    final isConflict = prefs.remoteNewer;
    final message = isConflict
        ? 'Your Google Drive backup is newer than this device. '
            'Auto-backup is paused to avoid overwriting it — restore to sync up.'
        : (prefs.lastError ?? 'Last automatic backup failed.');
    final color = isConflict ? AppColors.green : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  isConflict
                      ? Icons.cloud_sync_outlined
                      : Icons.error_outline,
                  size: 18,
                  color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message,
                    style: AppTextStyles.caption
                        .copyWith(color: context.ink, height: 1.4)),
              ),
            ],
          ),
          if (isConflict) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.ink,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: onRestore,
                icon: const Icon(Icons.cloud_download_outlined, size: 18),
                label: const Text('Restore'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _relativeTime(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 30) return '${d.inDays}d ago';
  return '${(d.inDays / 30).floor()}mo ago';
}

class _Toggles extends ConsumerWidget {
  const _Toggles({required this.prefs});
  final BackupPrefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.hairline),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: prefs.enabled,
            activeThumbColor: AppColors.green,
            title: Text('Auto-backup',
                style: AppTextStyles.body
                    .copyWith(color: context.ink, fontWeight: FontWeight.w600)),
            subtitle: Text('Once a day on app launch',
                style: AppTextStyles.caption
                    .copyWith(color: context.inkMuted)),
            onChanged: (v) =>
                ref.read(backupPrefsProvider.notifier).setEnabled(v),
          ),
          Divider(height: 1, color: context.hairline),
          SwitchListTile.adaptive(
            value: prefs.wifiOnly,
            activeThumbColor: AppColors.green,
            title: Text('Wi-Fi only',
                style: AppTextStyles.body.copyWith(
                    color: prefs.enabled ? context.ink : context.inkSubtle,
                    fontWeight: FontWeight.w600)),
            subtitle: Text('Skip auto-backup on mobile data',
                style: AppTextStyles.caption
                    .copyWith(color: context.inkMuted)),
            onChanged: prefs.enabled
                ? (v) =>
                    ref.read(backupPrefsProvider.notifier).setWifiOnly(v)
                : null,
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.prefs,
    required this.busy,
    required this.onBackup,
    required this.onRestore,
  });
  final BackupPrefs prefs;
  final bool busy;
  final VoidCallback onBackup;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.ink,
            ),
            onPressed: busy ? null : onBackup,
            icon: busy
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.cloud_upload_outlined),
            label: const Text('Back up now'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: busy ? null : onRestore,
            icon: const Icon(Icons.cloud_download_outlined),
            label: const Text('Restore'),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lock_outline, size: 16, color: AppColors.ink),
            const SizedBox(width: 6),
            Text('Private app folder',
                style: AppTextStyles.title.copyWith(
                    color: AppColors.ink, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          Text(
            'Backups are saved to a private folder in your Google Drive. '
            "Only this app can read them — they don't appear in Drive's UI "
            "and don't count toward visible storage.",
            style: AppTextStyles.caption.copyWith(
                color: AppColors.ink.withValues(alpha: 0.75), height: 1.5),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => launchUrl(
                Uri.parse(
                    'https://developers.google.com/drive/api/guides/appdata'),
                mode: LaunchMode.externalApplication),
            child: Text('Learn more',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }
}

class _RestoreSheet extends StatelessWidget {
  const _RestoreSheet({required this.info});
  final RemoteBackupInfo info;

  @override
  Widget build(BuildContext context) {
    final meta = info.metadata;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 56,
              width: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.greenSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.cloud_done_outlined,
                  color: AppColors.ink, size: 28),
            ),
            const SizedBox(height: 16),
            Text('We found a backup',
                style: AppTextStyles.headline.copyWith(color: context.ink)),
            const SizedBox(height: 6),
            Text(
              meta != null
                  ? '${_relativeTime(meta.createdAt)} · ${meta.recordCount} records · v${meta.appVersion}'
                  : _relativeTime(info.modifiedAt),
              style:
                  AppTextStyles.caption.copyWith(color: context.inkMuted),
            ),
            const SizedBox(height: 6),
            Text('${(info.sizeBytes / 1024).toStringAsFixed(1)} KB',
                style:
                    AppTextStyles.caption.copyWith(color: context.inkSubtle)),
            const SizedBox(height: 20),
            Text(
              'Restoring will replace any data currently on this device.',
              style: AppTextStyles.body.copyWith(color: context.inkMuted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.ink,
              ),
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Restore'),
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisplayNameCard extends ConsumerStatefulWidget {
  const _DisplayNameCard();

  @override
  ConsumerState<_DisplayNameCard> createState() => _DisplayNameCardState();
}

class _DisplayNameCardState extends ConsumerState<_DisplayNameCard> {
  late final TextEditingController _controller;
  String _saved = '';

  @override
  void initState() {
    super.initState();
    _saved = ref.read(displayNameProvider);
    _controller = TextEditingController(text: _saved);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(displayNameProvider, (prev, next) {
      if (next != _saved && _controller.text == _saved) {
        _saved = next;
        _controller.text = next;
        _controller.selection = TextSelection.collapsed(offset: next.length);
      }
    });
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: context.hairline),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Your name',
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (_, v, _) {
                final dirty = v.text.trim() != _saved;
                return FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onPressed: dirty ? _save : null,
                  child: const Text('Save'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    await ref.read(displayNameProvider.notifier).set(name);
    setState(() => _saved = name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved'), duration: Duration(seconds: 1)),
    );
  }
}
