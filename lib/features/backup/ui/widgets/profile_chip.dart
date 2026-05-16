import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../data/backup_prefs.dart';
import '../../data/google_auth.dart';
import '../backup_page.dart';

class ProfileChip extends ConsumerWidget {
  const ProfileChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(googleAuthProvider);
    final prefs = ref.watch(backupPrefsProvider);

    final isFresh = prefs.lastBackupAt != null &&
        DateTime.now().difference(prefs.lastBackupAt!) <
            const Duration(hours: 24);
    final showDot = prefs.enabled && account != null && isFresh;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BackupPage()),
        ),
        child: SizedBox(
          height: 40,
          width: 40,
          child: Stack(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.surface,
                  border: Border.all(color: context.hairline),
                ),
                clipBehavior: Clip.antiAlias,
                child: _AvatarInner(account: account),
              ),
              if (showDot)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarInner extends StatelessWidget {
  const _AvatarInner({required this.account});
  final dynamic account;

  @override
  Widget build(BuildContext context) {
    final photo = account?.photoUrl as String?;
    if (account == null) {
      return Center(
        child: Icon(Icons.person_outline, size: 18, color: context.ink),
      );
    }
    if (photo == null || photo.isEmpty) {
      final initials = _initialsOf(account?.displayName as String? ??
          account?.email as String? ??
          '?');
      return Container(
        color: AppColors.greenSoft,
        alignment: Alignment.center,
        child: Text(initials,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black)),
      );
    }
    return Image.network(
      photo,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.greenSoft,
        alignment: Alignment.center,
        child: Icon(Icons.person, size: 18, color: context.ink),
      ),
    );
  }

  String _initialsOf(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
