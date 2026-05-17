import 'package:flutter/widgets.dart';

import 'currency.dart';

/// Shared motion tokens so every animation in the app reads as one language.
class AppMotion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration med = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeIn;
}

/// Fade + slight upward slide on first build. Cheap, no controller.
/// Drive entrance staggers by passing different `delay`s.
class FadeIn extends StatelessWidget {
  const FadeIn({
    super.key,
    required this.child,
    this.duration = AppMotion.med,
    this.curve = AppMotion.enter,
    this.delay = Duration.zero,
    this.offset = 6,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: _DelayCurve(delay: delay, total: duration + delay, inner: curve),
      builder: (_, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * offset),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _DelayCurve extends Curve {
  const _DelayCurve(
      {required this.delay, required this.total, required this.inner});
  final Duration delay;
  final Duration total;
  final Curve inner;

  @override
  double transformInternal(double t) {
    final delayFrac =
        total.inMilliseconds == 0 ? 0 : delay.inMilliseconds / total.inMilliseconds;
    if (t < delayFrac) return 0;
    final remap = (t - delayFrac) / (1 - delayFrac);
    return inner.transform(remap);
  }
}

/// AnimatedSwitcher with our tokens, fade-only.
class XSwitcher extends StatelessWidget {
  const XSwitcher({
    super.key,
    required this.child,
    this.duration = AppMotion.med,
  });
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
      child: child,
    );
  }
}

/// Tweens a money value between renders. Re-renders only when [minor] or
/// [currency.code] changes.
class AnimatedMoney extends StatefulWidget {
  const AnimatedMoney({
    super.key,
    required this.minor,
    required this.currency,
    this.style,
    this.duration = AppMotion.slow,
    this.signed = false,
    this.negative = false,
  });

  final int minor;
  final CurrencyOption currency;
  final TextStyle? style;
  final Duration duration;
  final bool signed;
  final bool negative;

  @override
  State<AnimatedMoney> createState() => _AnimatedMoneyState();
}

class _AnimatedMoneyState extends State<AnimatedMoney> {
  late int _from;

  @override
  void initState() {
    super.initState();
    _from = widget.minor;
  }

  @override
  void didUpdateWidget(covariant AnimatedMoney old) {
    super.didUpdateWidget(old);
    if (old.minor != widget.minor || old.currency.code != widget.currency.code) {
      _from = old.minor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _from.toDouble(), end: widget.minor.toDouble()),
      duration: widget.duration,
      curve: AppMotion.enter,
      builder: (_, v, _) {
        final n = v.round();
        final text = widget.signed
            ? formatMoneySigned(n, widget.currency, negative: widget.negative)
            : formatMoney(n, widget.currency);
        return Text(text, style: widget.style);
      },
    );
  }
}

/// Scales down briefly while pressed.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.96,
  });
  final Widget child;
  final VoidCallback onTap;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        child: widget.child,
      ),
    );
  }
}
