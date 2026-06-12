import 'dart:ui' as ui;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/providers.dart';
import '../features/backup/data/backup_repo.dart';
import '../features/home/ui/home_page.dart';
import '../features/loans/ui/loans_page.dart';
import '../features/projects/ui/projects_page.dart';
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
    ProjectsPage(),
    SettingsPage(),
  ];

  static const _items = <_NavItem>[
    _NavItem('Home', Icons.home_outlined, Icons.home),
    _NavItem('Records', Icons.receipt_long_outlined, Icons.receipt_long),
    _NavItem('Loans', Icons.handshake_outlined, Icons.handshake),
    _NavItem('Projects', Icons.folder_outlined, Icons.folder),
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

    // On tap: page slides AND pill animates — but independently so the pill
    // travels directly from source to target without lighting up intermediate tabs.
    ref.listen<ShellNavState>(shellNavProvider, (prev, next) {
      if (prev?.current == next.current) return;
      if (!_pageController.hasClients) return;
      final currentPage = _pageController.page?.round() ?? next.current;
      if (currentPage == next.current) return;
      _isSyncingFromProvider = true;
      _pageController
          .animateToPage(
            next.current,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          )
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

class _FloatingNavBar extends StatefulWidget {
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
  State<_FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<_FloatingNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pillCtrl;
  double _pillFrom = 0;
  double _pillTo = 0;
  // True while a tap-driven pill animation is running; false = follow finger.
  bool _tapAnimating = false;

  @override
  void initState() {
    super.initState();
    _pillFrom = widget.index.toDouble();
    _pillTo = widget.index.toDouble();
    _pillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() {
        if (mounted) setState(() {});
      });
    widget.pageController.addListener(_onPageScroll);
  }

  @override
  void didUpdateWidget(_FloatingNavBar old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      // Tap navigation — slide pill directly from current position to target.
      _pillFrom = _effectivePage;
      _pillTo = widget.index.toDouble();
      _tapAnimating = true;
      _pillCtrl
        ..reset()
        ..forward().whenComplete(() {
          if (mounted) setState(() => _tapAnimating = false);
        });
    }
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_onPageScroll);
    _pillCtrl.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    // During swipe (not a tap-driven animation) rebuild so pill tracks finger.
    if (!_tapAnimating && mounted) setState(() {});
  }

  // Smooth position used by all pills.
  double get _effectivePage {
    if (_tapAnimating) {
      final t = Curves.easeInOutCubic.transform(_pillCtrl.value);
      return _pillFrom + (_pillTo - _pillFrom) * t;
    }
    return widget.pageController.hasClients
        ? (widget.pageController.page ?? widget.index.toDouble())
        : widget.index.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final safePad = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final barColor = isDark
        ? Colors.black.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.88);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.07);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.30)
        : Colors.black.withValues(alpha: 0.07);

    final page = _effectivePage;
    double exp(int i) => (1.0 - (page - i).abs()).clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + safePad),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: isDark ? 24 : 20,
                  spreadRadius: isDark ? 0 : 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                for (int i = 0; i < widget.items.length; i++)
                  _NavPill(
                    item: widget.items[i],
                    expansion: exp(i),
                    isDark: isDark,
                    onTap: () => widget.onTap(i),
                  ),
              ],
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
    required this.isDark,
    required this.onTap,
  });
  final _NavItem item;
  final double expansion; // 0 = inactive, 1 = fully selected
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Inactive icon: dark in light mode, muted white in dark mode
    final inactiveIconColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.70);

    // Active icon + label: always green. Pill bg: black in light, greenSoft in dark.
    final iconColor = Color.lerp(inactiveIconColor, AppColors.green, expansion)!;
    const labelColor = AppColors.green;
    final pillColor = Color.lerp(
      Colors.transparent,
      isDark ? AppColors.greenSoft : Colors.black,
      expansion,
    )!;
    final labelOpacity =
        Curves.easeIn.transform(((expansion - 0.35) / 0.65).clamp(0.0, 1.0));

    return Flexible(
      flex: (100 + (expansion * 110)).round(),
      fit: FlexFit.tight,
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
                        style: TextStyle(
                          color: labelColor,
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
