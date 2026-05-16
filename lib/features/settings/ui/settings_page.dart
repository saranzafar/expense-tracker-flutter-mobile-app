import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency.dart';
import '../../../core/theme.dart';
import '../../../data/onboarding_repo.dart';
import '../../../data/settings_repo.dart';
import '../../about/ui/about_page.dart';
import '../../backup/ui/backup_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            _Section(title: 'Appearance', children: [
              _Tile(
                icon: Icons.brightness_6_outlined,
                title: 'Theme',
                subtitle: _themeLabel(mode),
                onTap: () => _openThemeSheet(context, ref, mode),
              ),
            ]),
            const SizedBox(height: 16),
            _Section(title: 'Money', children: [
              _Tile(
                icon: Icons.payments_outlined,
                title: 'Currency',
                subtitle: '${currency.code} · ${currency.symbol}',
                trailing: Text(currency.flag,
                    style: const TextStyle(fontSize: 22)),
                onTap: () => _openCurrencySheet(context, ref, currency),
              ),
            ]),
            const SizedBox(height: 16),
            _Section(title: 'Sync', children: [
              _Tile(
                icon: Icons.cloud_outlined,
                title: 'Backup',
                subtitle: 'Google Drive · optional',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BackupPage()),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _Section(title: 'About', children: [
              _Tile(
                icon: Icons.person_outline,
                title: 'About',
                subtitle: 'Author · links · source',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutPage()),
                ),
              ),
              _Tile(
                  icon: Icons.info_outline,
                  title: 'App version',
                  subtitle: '1.0.0'),
            ]),
            const SizedBox(height: 16),
            _Section(title: 'Developer', children: [
              _Tile(
                icon: Icons.refresh,
                title: 'Reset onboarding',
                subtitle: 'Show intro screens again next launch',
                onTap: () async {
                  await ref.read(onboardingRepoProvider).reset();
                  ref.invalidate(onboardingSeenProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Onboarding reset')),
                    );
                  }
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

String _themeLabel(ThemeMode m) {
  switch (m) {
    case ThemeMode.light:
      return 'Light';
    case ThemeMode.dark:
      return 'Dark';
    case ThemeMode.system:
      return 'Follow system';
  }
}

Future<void> _openThemeSheet(
    BuildContext context, WidgetRef ref, ThemeMode current) async {
  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Theme',
                style: AppTextStyles.headline.copyWith(color: context.ink)),
            const SizedBox(height: 16),
            for (final m in const [
              ThemeMode.light,
              ThemeMode.dark,
              ThemeMode.system,
            ]) ...[
              _ChoiceTile(
                icon: m == ThemeMode.light
                    ? Icons.light_mode_outlined
                    : m == ThemeMode.dark
                        ? Icons.dark_mode_outlined
                        : Icons.brightness_auto_outlined,
                title: _themeLabel(m),
                selected: m == current,
                onTap: () async {
                  await ref.read(themeModeProvider.notifier).set(m);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    ),
  );
}

Future<void> _openCurrencySheet(
    BuildContext context, WidgetRef ref, CurrencyOption current) async {
  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Currency',
                style: AppTextStyles.headline.copyWith(color: context.ink)),
            const SizedBox(height: 4),
            Text('Display-only — your records stay the same.',
                style: AppTextStyles.caption
                    .copyWith(color: context.inkMuted)),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.55,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: kCurrencies.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final c = kCurrencies[i];
                  return _ChoiceTile(
                    leadingText: c.flag,
                    title: '${c.code} · ${c.name}',
                    subtitle: c.symbol,
                    selected: c.code == current.code,
                    onTap: () async {
                      await ref
                          .read(currencyProvider.notifier)
                          .set(c.code);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(title,
              style: AppTextStyles.caption.copyWith(color: context.inkMuted)),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: context.hairline),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, color: context.hairline),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.ink),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.body.copyWith(
                          color: context.ink, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.caption
                          .copyWith(color: context.inkMuted)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && onTap != null)
              Icon(Icons.chevron_right, color: context.inkSubtle),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    this.icon,
    this.leadingText,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final IconData? icon;
  final String? leadingText;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
              color: selected ? AppColors.green : context.hairline,
              width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(16),
          color: selected ? AppColors.greenSoft : Colors.transparent,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22, color: context.ink),
              const SizedBox(width: 12),
            ] else if (leadingText != null) ...[
              Text(leadingText!, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.body.copyWith(
                          color: context.ink, fontWeight: FontWeight.w600)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: AppTextStyles.caption
                            .copyWith(color: context.inkMuted)),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.green, size: 22),
          ],
        ),
      ),
    );
  }
}
