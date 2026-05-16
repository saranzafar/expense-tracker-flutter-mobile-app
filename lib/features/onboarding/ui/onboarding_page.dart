import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme.dart';
import '../../../data/onboarding_repo.dart';
import '../../../shell/home_shell.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = <_Slide>[
    _Slide(
      svg: 'assets/illustrations/welcome.svg',
      title: 'Welcome to Xpense Tracker',
      body: 'A calm, focused way to keep track of your money.',
    ),
    _Slide(
      svg: 'assets/illustrations/track.svg',
      title: 'Track expenses & income',
      body:
          'Log records in seconds. Your balance updates instantly — no clutter.',
    ),
    _Slide(
      svg: 'assets/illustrations/loans.svg',
      title: 'Track loans you give',
      body:
          'Lend money to a friend? Track it with an expected return date.',
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingRepoProvider).markSeen();
    ref.invalidate(onboardingSeenProvider);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => const HomeShell(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Xpense Tracker',
                      style: AppTextStyles.title
                          .copyWith(fontWeight: FontWeight.w700)),
                  TextButton(
                    onPressed: _finish,
                    child: Text('Skip',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.inkMuted)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _SlideView(slide: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < _pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 6,
                          width: i == _page ? 22 : 6,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? AppColors.green
                                : AppColors.hairline,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.ink,
                      ),
                      onPressed: () {
                        if (_isLast) {
                          _finish();
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                      child: Text(_isLast ? 'Get started' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final String svg;
  final String title;
  final String body;
  const _Slide({required this.svg, required this.title, required this.body});
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: SvgPicture.asset(slide.svg,
                  height: 240, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 24),
          Text(slide.title,
              style: AppTextStyles.headline.copyWith(fontSize: 26),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(slide.body,
              style: AppTextStyles.body.copyWith(color: AppColors.inkMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
