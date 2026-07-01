import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// The cat's overall disposition, derived from the user's finances.
enum MascotMood { happy, content, worried, sleepy }

/// A one-shot reaction played on top of the idle animation.
enum MascotReaction { none, pet, income, expense, celebrate }

/// "Xpy" — a fully code-drawn pixel cat. No image assets: the body is painted
/// on a pixel grid so it stays crisp at any size and adapts to light/dark
/// (body = ink, eyes/accents = green). It's always subtly alive (breathing,
/// blinking, tail wag) and plays particle reactions on demand.
class PixelCat extends StatefulWidget {
  const PixelCat({
    super.key,
    this.mood = MascotMood.content,
    this.reaction = MascotReaction.none,
    this.reactionTick = 0,
    this.size = 96,
  });

  final MascotMood mood;

  /// The reaction to play. Combined with [reactionTick] so the same reaction
  /// can be re-triggered (tap twice → hearts twice).
  final MascotReaction reaction;
  final int reactionTick;
  final double size;

  @override
  State<PixelCat> createState() => _PixelCatState();
}

class _PixelCatState extends State<PixelCat>
    with TickerProviderStateMixin {
  late final AnimationController _idle;
  late final AnimationController _react;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _react = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    if (widget.reaction != MascotReaction.none) _react.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant PixelCat old) {
    super.didUpdateWidget(old);
    if (widget.reactionTick != old.reactionTick &&
        widget.reaction != MascotReaction.none) {
      _react.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _react.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = context.ink;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _react]),
        builder: (_, _) {
          final t = _idle.value; // 0..1 loop
          return CustomPaint(
            painter: _CatPainter(
              body: body,
              accent: AppColors.green,
              danger: AppColors.danger,
              t: t,
              mood: widget.mood,
              reaction: widget.reaction,
              reactionProgress: _react.isAnimating || _react.value > 0
                  ? _react.value
                  : 0,
            ),
          );
        },
      ),
    );
  }
}

class _CatPainter extends CustomPainter {
  _CatPainter({
    required this.body,
    required this.accent,
    required this.danger,
    required this.t,
    required this.mood,
    required this.reaction,
    required this.reactionProgress,
  });

  final Color body;
  final Color accent;
  final Color danger;
  final double t;
  final MascotMood mood;
  final MascotReaction reaction;
  final double reactionProgress;

  // 16 cols x 14 rows sitting-cat silhouette. '#' = body, ' ' = empty.
  static const List<String> _map = [
    '  #        #    ',
    ' ###      ###   ',
    ' ####    ####   ',
    ' ############   ',
    '###############',
    '###############',
    '###############',
    '###############',
    '################',
    '################',
    '################',
    ' ############## ',
    '  ############  ',
    '   ##########   ',
  ];

  static const int _cols = 16;
  static const int _rows = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _cols;
    // Breathing bob + a gentle settle for sleepy.
    final bob = mood == MascotMood.sleepy
        ? 0.0
        : math.sin(t * math.pi * 2) * cell * 0.35;
    final dy = -bob;

    final paint = Paint()..isAntiAlias = false;

    void fill(int col, int row, Color c, {double ox = 0, double oy = 0}) {
      paint.color = c;
      canvas.drawRect(
        Rect.fromLTWH(
          col * cell + ox,
          row * cell + oy + dy,
          cell + 0.5,
          cell + 0.5,
        ),
        paint,
      );
    }

    // ── Tail (wags horizontally) ────────────────────────────────────────────
    final wag = math.sin(t * math.pi * 2 * 2) *
        (mood == MascotMood.happy ? 1.4 : 0.8);
    for (int i = 0; i < 4; i++) {
      final tailRow = 8 + i;
      final shift = i >= 2 ? wag : 0.0;
      fill(15, tailRow, body, ox: shift * cell * 0.5);
    }

    // ── Body ────────────────────────────────────────────────────────────────
    for (int r = 0; r < _rows; r++) {
      final line = _map[r];
      for (int c = 0; c < line.length && c < _cols; c++) {
        if (line[c] == '#') fill(c, r, body);
      }
    }

    // ── Eyes ──────────────────────────────────────────────────────────────
    // Blink once per loop; sleepy keeps them shut.
    final blinking = t > 0.90 && t < 0.965;
    final closed = mood == MascotMood.sleepy || blinking;
    const leftEye = 4, rightEye = 10, eyeTop = 6;
    if (closed) {
      // A single line of eye = closed/sleepy.
      fill(leftEye, eyeTop + 1, accent);
      fill(leftEye + 1, eyeTop + 1, accent);
      fill(rightEye, eyeTop + 1, accent);
      fill(rightEye + 1, eyeTop + 1, accent);
    } else {
      for (final ex in [leftEye, rightEye]) {
        fill(ex, eyeTop, accent);
        fill(ex + 1, eyeTop, accent);
        fill(ex, eyeTop + 1, accent);
        fill(ex + 1, eyeTop + 1, accent);
      }
      // Worried: add a small brow slightly raised on the inner corners.
      if (mood == MascotMood.worried) {
        fill(leftEye + 1, eyeTop - 1, body);
        fill(rightEye, eyeTop - 1, body);
      }
    }

    // ── Mouth (mood-driven) ─────────────────────────────────────────────────
    switch (mood) {
      case MascotMood.happy:
        // small upward smile
        fill(6, 9, accent);
        fill(7, 10, accent);
        fill(8, 10, accent);
        fill(9, 9, accent);
        // blush
        fill(3, 8, accent.withValues(alpha: 0.35));
        fill(12, 8, accent.withValues(alpha: 0.35));
        break;
      case MascotMood.content:
        fill(7, 9, accent);
        fill(8, 9, accent);
        break;
      case MascotMood.worried:
        // downturned frown
        fill(6, 10, danger.withValues(alpha: 0.8));
        fill(7, 9, danger.withValues(alpha: 0.8));
        fill(8, 9, danger.withValues(alpha: 0.8));
        fill(9, 10, danger.withValues(alpha: 0.8));
        break;
      case MascotMood.sleepy:
        // tiny mouth
        fill(7, 9, accent.withValues(alpha: 0.6));
        break;
    }

    // ── Reaction particles + persistent Zzz ─────────────────────────────────
    _paintParticles(canvas, size, cell);
  }

  void _paintParticles(Canvas canvas, Size size, double cell) {
    // Persistent Zzz while sleepy.
    if (mood == MascotMood.sleepy) {
      _drawZ(canvas, size, cell, phase: (t) * 1.0);
    }

    if (reactionProgress <= 0) return;
    final p = reactionProgress; // 0..1
    final rise = (1 - p) * cell * 4; // float up
    final fade = (1 - p).clamp(0.0, 1.0);

    switch (reaction) {
      case MascotReaction.pet:
        _drawHeart(canvas, cell, size.width * 0.30,
            size.height * 0.15 - rise, accent.withValues(alpha: fade));
        _drawHeart(canvas, cell, size.width * 0.62,
            size.height * 0.10 - rise * 1.2, accent.withValues(alpha: fade));
        break;
      case MascotReaction.income:
      case MascotReaction.celebrate:
        _drawStar(canvas, cell, size.width * 0.22,
            size.height * 0.18 - rise, accent.withValues(alpha: fade));
        _drawStar(canvas, cell, size.width * 0.72,
            size.height * 0.12 - rise * 1.3, accent.withValues(alpha: fade));
        _drawStar(canvas, cell, size.width * 0.48,
            size.height * 0.05 - rise * 0.8, accent.withValues(alpha: fade));
        break;
      case MascotReaction.expense:
        // a small crumb/coin dropping down
        final drop = p * cell * 3;
        final paint = Paint()
          ..isAntiAlias = false
          ..color = danger.withValues(alpha: fade);
        canvas.drawRect(
          Rect.fromLTWH(size.width * 0.5, size.height * 0.35 + drop,
              cell, cell),
          paint,
        );
        break;
      case MascotReaction.none:
        break;
    }
  }

  void _drawHeart(Canvas canvas, double cell, double x, double y, Color c) {
    final paint = Paint()
      ..isAntiAlias = false
      ..color = c;
    // 5x5 pixel heart
    const pat = [
      '.#.#.',
      '#####',
      '#####',
      '.###.',
      '..#..',
    ];
    final s = cell * 0.5;
    for (int r = 0; r < pat.length; r++) {
      for (int col = 0; col < pat[r].length; col++) {
        if (pat[r][col] == '#') {
          canvas.drawRect(
              Rect.fromLTWH(x + col * s, y + r * s, s + 0.5, s + 0.5), paint);
        }
      }
    }
  }

  void _drawStar(Canvas canvas, double cell, double x, double y, Color c) {
    final paint = Paint()
      ..isAntiAlias = false
      ..color = c;
    const pat = ['.#.', '###', '.#.'];
    final s = cell * 0.5;
    for (int r = 0; r < pat.length; r++) {
      for (int col = 0; col < pat[r].length; col++) {
        if (pat[r][col] == '#') {
          canvas.drawRect(
              Rect.fromLTWH(x + col * s, y + r * s, s + 0.5, s + 0.5), paint);
        }
      }
    }
  }

  void _drawZ(Canvas canvas, Size size, double cell, {required double phase}) {
    final float = math.sin(phase * math.pi * 2) * cell * 0.4;
    final tp = TextPainter(
      text: TextSpan(
        text: 'z',
        style: TextStyle(
          color: accent.withValues(alpha: 0.8),
          fontSize: cell * 2.2,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width * 0.72, size.height * 0.05 + float));
  }

  @override
  bool shouldRepaint(covariant _CatPainter old) => true;
}
