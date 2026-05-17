import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../features/home/ui/home_page.dart';
import '../features/loans/ui/loans_page.dart';
import '../features/records/ui/record_form_page.dart';
import '../features/records/ui/records_list_page.dart';
import '../features/settings/ui/settings_page.dart';
import '../data/database.dart';

/// State for the bottom-nav: current tab + history stack of previously
/// visited tabs (most recent at the end; does NOT include `current`).
class ShellNavState {
  final int current;
  final List<int> history;
  const ShellNavState({this.current = 0, this.history = const []});
}

class ShellNavController extends Notifier<ShellNavState> {
  @override
  ShellNavState build() => const ShellNavState();

  void goTo(int index) {
    if (index == state.current) return;
    final newHistory = [...state.history]..remove(index);
    newHistory.add(state.current);
    state = ShellNavState(current: index, history: newHistory);
  }

  /// Returns true if a previous tab was restored (back consumed).
  bool popTab() {
    if (state.history.isEmpty) return false;
    final newHistory = [...state.history];
    final prev = newHistory.removeLast();
    state = ShellNavState(current: prev, history: newHistory);
    return true;
  }
}

final shellNavProvider =
    NotifierProvider<ShellNavController, ShellNavState>(
  ShellNavController.new,
);

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  bool _exitArmed = false;

  static const _pages = <Widget>[
    HomePage(),
    RecordsListPage(),
    LoansPage(),
    SettingsPage(),
  ];

  static const _items = <_NavItem>[
    _NavItem('Home', Icons.home_outlined, Icons.home),
    _NavItem('Records', Icons.receipt_long_outlined, Icons.receipt_long),
    _NavItem('Loans', Icons.handshake_outlined, Icons.handshake),
    _NavItem('Settings', Icons.settings_outlined, Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(shellNavProvider).current;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = ref.read(shellNavProvider.notifier);
        if (nav.popTab()) return;
        if (_exitArmed) {
          await SystemNavigator.pop();
          return;
        }
        _exitArmed = true;
        final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
        messenger
            .showSnackBar(const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ))
            .closed
            .then((_) {
          if (mounted) _exitArmed = false;
        });
      },
      child: Scaffold(
        extendBody: true,
        body: AnimatedSwitcher(
          duration: AppMotion.med,
          switchInCurve: AppMotion.enter,
          switchOutCurve: AppMotion.exit,
          transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
          child: KeyedSubtree(
            key: ValueKey(index),
            child: _pages[index],
          ),
        ),
        floatingActionButton: SizedBox(
          height: 64,
          width: 64,
          child: FloatingActionButton(
            onPressed: () => _openAddSheet(context),
            tooltip: 'Add record',
            child: const Icon(Icons.add, size: 28),
          ),
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _BottomBar(
          items: _items,
          index: index,
          onTap: (i) => ref.read(shellNavProvider.notifier).goTo(i),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData iconSelected;
  const _NavItem(this.label, this.icon, this.iconSelected);
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.items,
    required this.index,
    required this.onTap,
  });
  final List<_NavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(top: BorderSide(color: context.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i == 2) const SizedBox(width: 72),
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: index == i,
                    onTap: () => onTap(i),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton(
      {required this.item, required this.selected, required this.onTap});
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.ink : context.inkSubtle;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.enter,
            height: 3,
            width: selected ? 24 : 0,
            decoration: BoxDecoration(
              color: selected ? AppColors.green : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: AppMotion.fast,
            transitionBuilder: (c, a) =>
                FadeTransition(opacity: a, child: c),
            child: Icon(selected ? item.iconSelected : item.icon,
                key: ValueKey(selected),
                color: color,
                size: 22),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: AppMotion.fast,
            style: AppTextStyles.caption.copyWith(color: color),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}

Future<void> _openAddSheet(BuildContext context) async {
  final picked = await showModalBottomSheet<RecordType>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add new',
                style: AppTextStyles.headline.copyWith(color: context.ink)),
            const SizedBox(height: 16),
            _TypeCard(
              icon: Icons.arrow_upward_rounded,
              title: 'Expense',
              subtitle: 'Money you spent',
              onTap: () => Navigator.pop(ctx, RecordType.expense),
            ),
            const SizedBox(height: 10),
            _TypeCard(
              icon: Icons.arrow_downward_rounded,
              title: 'Income',
              subtitle: 'Money you received',
              onTap: () => Navigator.pop(ctx, RecordType.income),
            ),
            const SizedBox(height: 10),
            _TypeCard(
              icon: Icons.handshake_outlined,
              title: 'Loan given',
              subtitle: 'Money you lent to someone',
              onTap: () => Navigator.pop(ctx, RecordType.loanGiven),
              accent: true,
            ),
          ],
        ),
      ),
    ),
  );
  if (picked != null && context.mounted) {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RecordFormPage(type: picked),
    ));
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
                color: accent ? AppColors.greenSoft : Colors.transparent,
                border: Border.all(color: context.hairline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: context.ink, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          AppTextStyles.title.copyWith(color: context.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.caption
                          .copyWith(color: context.inkMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.inkSubtle),
          ],
        ),
      ),
    );
  }
}
