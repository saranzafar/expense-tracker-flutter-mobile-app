import 'dart:ui' as ui;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/motion.dart';
import '../data/providers.dart';
import '../features/backup/data/backup_repo.dart';
import '../features/home/ui/home_page.dart';
import '../features/loans/ui/loans_page.dart';
import '../features/records/ui/records_list_page.dart';
import '../features/settings/ui/settings_page.dart';

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
  bool _wasOnline = false;
  bool _isSyncingFromProvider = false;
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then((results) {
      if (mounted) {
        _wasOnline = results.any((r) => r != ConnectivityResult.none);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onCameOnline() async {
    final result = await ref.read(backupRepoProvider).autoBackupIfDue();
    if (!mounted || result == null) return;
    if (result.outcome == BackupOutcome.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backed up to Drive ✓'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

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

    ref.listen<AsyncValue<List<ConnectivityResult>>>(
      connectivityProvider,
      (_, next) {
        final isOnline =
            next.valueOrNull?.any((r) => r != ConnectivityResult.none) ?? false;
        if (!_wasOnline && isOnline) _onCameOnline();
        _wasOnline = isOnline;
      },
    );

    // Sync PageView when nav bar tapped (or back button pops tab).
    ref.listen<ShellNavState>(shellNavProvider, (prev, next) {
      if (prev?.current == next.current) return;
      if (!_pageController.hasClients) return;
      final currentPage = _pageController.page?.round() ?? next.current;
      if (currentPage == next.current) return;
      _isSyncingFromProvider = true;
      _pageController
          .animateToPage(next.current,
              duration: AppMotion.med, curve: AppMotion.enter)
          .whenComplete(() {
        if (mounted) _isSyncingFromProvider = false;
      });
    });

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
        body: PageView(
          controller: _pageController,
          physics: const ClampingScrollPhysics(),
          onPageChanged: (i) {
            if (_isSyncingFromProvider) return;
            ref.read(shellNavProvider.notifier).goTo(i);
          },
          children: _pages,
        ),
        bottomNavigationBar: _FloatingNavBar(
          items: _items,
          index: index,
          pageController: _pageController,
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

// ── Floating nav bar ─────────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.items,
    required this.index,
    required this.pageController,
    required this.onTap,
  });
  final List<_NavItem> items;
  final int index;
  final PageController pageController;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final safePad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + safePad),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: AnimatedBuilder(
              animation: pageController,
              builder: (context, _) {
                final page = pageController.hasClients
                    ? (pageController.page ?? index.toDouble())
                    : index.toDouble();

                // expansion 0..1 for each nav item
                double exp(int i) =>
                    (1.0 - (page - i).abs()).clamp(0.0, 1.0);

                return Row(
                  children: [
                    for (int i = 0; i < items.length; i++)
                      _NavPill(
                        item: items[i],
                        expansion: exp(i),
                        onTap: () => onTap(i),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Expands horizontally when selected to reveal the label.
class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.item,
    required this.expansion,
    required this.onTap,
  });
  final _NavItem item;
  final double expansion; // 0 = inactive, 1 = fully selected
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = Color.lerp(
      Colors.white.withValues(alpha: 0.50),
      Colors.white,
      expansion,
    )!;
    final pillColor = Color.lerp(
      Colors.transparent,
      const Color(0xFF3C3C3E),
      expansion,
    )!;
    final labelOpacity =
        Curves.easeIn.transform(((expansion - 0.35) / 0.65).clamp(0.0, 1.0));

    return Flexible(
      // Active item gets ~2× the width of an inactive item.
      flex: (100 + (expansion * 110)).round(),
      fit: FlexFit.tight, // pill fills its entire slot — no dead space
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: pillColor,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                expansion > 0.5 ? item.iconSelected : item.icon,
                color: iconColor,
                size: 20,
              ),
              // Smoothly reveal label by clipping its width
              ClipRect(
                child: Align(
                  widthFactor: expansion,
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: Opacity(
                      opacity: labelOpacity,
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1,
                        ),
                        maxLines: 1,
                      ),
                    ),
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
