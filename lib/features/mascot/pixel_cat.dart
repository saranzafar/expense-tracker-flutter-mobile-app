import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// The cat's overall disposition, derived from the user's finances.
enum MascotMood { happy, content, worried, sleepy }

/// A one-shot reaction played on top of the idle animation.
enum MascotReaction { none, pet, income, expense, celebrate }

/// A temporary facial expression, cycled when the user taps the cat.
enum MascotFace { none, wink, squint, surprised, heartEyes, starEyes, tongue, dizzy }

/// Autonomous micro-behaviours the cat performs on its own so it feels alive.
enum _Act { none, lookLeft, lookRight, earTwitch, yawn, wag, hop, walk }

/// "Xpy" — a fully code-drawn pixel cat. No image assets: the body is painted
/// on a pixel grid so it stays crisp at any size and adapts to light/dark
/// (body = ink, eyes/accents = green, hearts = red). It's always subtly alive
/// (breathing, blinking, tail wag) and, on its own, looks around, twitches its
/// ears, yawns, wags, hops and takes a little walk. Tap to change its face.
class PixelCat extends StatefulWidget {
  const PixelCat({
    super.key,
    this.mood = MascotMood.content,
    this.reaction = MascotReaction.none,
    this.reactionTick = 0,
    this.face = MascotFace.none,
    this.faceTick = 0,
    this.size = 96,
  });

  final MascotMood mood;
  final MascotReaction reaction;
  final int reactionTick;

  /// Temporary facial expression (from tapping). Combined with [faceTick] so
  /// re-selecting the same face still re-pops it.
  final MascotFace face;
  final int faceTick;
  final double size;

  @override
  State<PixelCat> createState() => _PixelCatState();
}

class _PixelCatState extends State<PixelCat> with TickerProviderStateMixin {
  late final AnimationController _idle;
  late final AnimationController _react;
  late final AnimationController _act; // autonomous micro-behaviour
  final _rng = math.Random();
  _Act _action = _Act.none;

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
    _act = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _action = _Act.none);
          _scheduleAction();
        }
      });
    if (widget.reaction != MascotReaction.none) _react.forward(from: 0);
    _scheduleAction();
  }

  void _scheduleAction() {
    final delayMs = 2400 + _rng.nextInt(3200);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted || _act.isAnimating) return;
      final a = _pickAction();
      _act.duration = a == _Act.walk
          ? const Duration(milliseconds: 2000)
          : const Duration(milliseconds: 1100);
      setState(() => _action = a);
      _act.forward(from: 0);
    });
  }

  _Act _pickAction() {
    if (widget.mood == MascotMood.sleepy) {
      return _rng.nextBool() ? _Act.earTwitch : _Act.yawn;
    }
    final pool = <_Act>[
      _Act.lookLeft,
      _Act.lookRight,
      _Act.earTwitch,
      _Act.yawn,
      _Act.wag,
      _Act.walk,
      if (widget.mood == MascotMood.happy) _Act.hop,
      if (widget.mood == MascotMood.happy) _Act.walk,
    ];
    return pool[_rng.nextInt(pool.length)];
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
    _act.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = context.ink;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _react, _act]),
        builder: (_, _) {
          return CustomPaint(
            painter: _CatPainter(
              body: body,
              accent: AppColors.green,
              danger: AppColors.danger,
              t: _idle.value,
              mood: widget.mood,
              reaction: widget.reaction,
              reactionProgress:
                  _react.value > 0 && _react.value < 1 ? _react.value : 0,
              face: widget.face,
              action: _action,
              actionRaw: _act.isAnimating ? _act.value : 0,
              actionBell: _act.isAnimating ? math.sin(_act.value * math.pi) : 0,
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
    required this.face,
    required this.action,
    required this.actionRaw,
    required this.actionBell,
  });

  final Color body;
  final Color accent;
  final Color danger;
  final double t;
  final MascotMood mood;
  final MascotReaction reaction;
  final double reactionProgress;
  final MascotFace face;
  final _Act action;
  final double actionRaw; // 0..1 raw progress of current action
  final double actionBell; // 0..1 bell curve of current action

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

    final bob = mood == MascotMood.sleepy
        ? 0.0
        : math.sin(t * math.pi * 2) * cell * 0.32;
    final hop = action == _Act.hop ? -actionBell * cell * 2.6 : 0.0;
    // Walk: glide left/right with a waddle bob.
    final walking = action == _Act.walk;
    final dxWalk =
        walking ? math.sin(actionRaw * math.pi * 2) * cell * 2.2 : 0.0;
    final waddle = walking
        ? -(math.sin(actionRaw * math.pi * 8)).abs() * cell * 0.35
        : 0.0;
    final dy = -bob + hop + waddle;

    final paint = Paint()..isAntiAlias = false;

    void fill(int col, int row, Color c, {double ox = 0, double oy = 0}) {
      paint.color = c;
      canvas.drawRect(
        Rect.fromLTWH(
          col * cell + ox + dxWalk,
          row * cell + oy + dy,
          cell + 0.5,
          cell + 0.5,
        ),
        paint,
      );
    }

    // ── Tail ────────────────────────────────────────────────────────────────
    final wagAmp = (mood == MascotMood.happy ? 1.4 : 0.8) +
        (action == _Act.wag ? actionBell * 2.2 : 0);
    final wag = math.sin(t * math.pi * 2 * 2) * wagAmp;
    for (int i = 0; i < 4; i++) {
      fill(15, 8 + i, body, ox: (i >= 2 ? wag : 0.0) * cell * 0.5);
    }

    // ── Body (right ear lifts on earTwitch; feet shuffle while walking) ──────
    final earLift = action == _Act.earTwitch ? -actionBell * cell * 0.6 : 0.0;
    final step = walking ? (math.sin(actionRaw * math.pi * 8) > 0 ? 1 : -1) : 0;
    for (int r = 0; r < _rows; r++) {
      final line = _map[r];
      for (int c = 0; c < line.length && c < _cols; c++) {
        if (line[c] != '#') continue;
        final isRightEar = r < 3 && c >= 9;
        // Bottom paws alternate up a touch to fake stepping.
        double oy = isRightEar ? earLift : 0;
        if (walking && r >= 12) {
          final leftHalf = c < 8;
          if ((leftHalf && step > 0) || (!leftHalf && step < 0)) {
            oy += -cell * 0.3;
          }
        }
        fill(c, r, body, oy: oy);
      }
    }

    // ── Face ────────────────────────────────────────────────────────────────
    if (face != MascotFace.none) {
      _paintFace(fill, cell);
    } else {
      _paintMoodFace(fill);
    }

    _paintParticles(canvas, size, cell);
  }

  // Tapped expressions.
  void _paintFace(void Function(int, int, Color, {double ox, double oy}) fill,
      double cell) {
    const l = 4, r = 10, top = 6;

    void eyeBlock(int ex) {
      fill(ex, top, accent);
      fill(ex + 1, top, accent);
      fill(ex, top + 1, accent);
      fill(ex + 1, top + 1, accent);
    }

    void smile() {
      fill(6, 9, accent);
      fill(7, 10, accent);
      fill(8, 10, accent);
      fill(9, 9, accent);
    }

    switch (face) {
      case MascotFace.wink:
        eyeBlock(l);
        fill(r, top + 1, accent); // right eye closed line
        fill(r + 1, top + 1, accent);
        smile();
        break;
      case MascotFace.squint: // ^_^
        fill(l, top, accent);
        fill(l + 1, top, accent);
        fill(r, top, accent);
        fill(r + 1, top, accent);
        smile();
        break;
      case MascotFace.surprised: // O_O + o mouth
        for (final ex in [l, r]) {
          for (int dxp = -1; dxp <= 1; dxp++) {
            for (int dyp = 0; dyp <= 1; dyp++) {
              fill(ex + dxp, top + dyp, accent);
            }
          }
        }
        fill(7, 10, danger.withValues(alpha: 0.6));
        fill(8, 10, danger.withValues(alpha: 0.6));
        break;
      case MascotFace.heartEyes:
        _miniHeart(fill, l - 1);
        _miniHeart(fill, r - 1);
        smile();
        break;
      case MascotFace.starEyes:
        _miniStar(fill, l - 1);
        _miniStar(fill, r - 1);
        smile();
        break;
      case MascotFace.tongue:
        eyeBlock(l);
        eyeBlock(r);
        smile();
        fill(7, 11, danger); // tongue
        fill(8, 11, danger);
        break;
      case MascotFace.dizzy: // x_x
        _miniX(fill, l - 1);
        _miniX(fill, r - 1);
        fill(7, 10, accent.withValues(alpha: 0.6));
        break;
      case MascotFace.none:
        break;
    }
  }

  void _miniHeart(void Function(int, int, Color, {double ox, double oy}) fill,
      int c) {
    fill(c, 5, danger);
    fill(c + 2, 5, danger);
    fill(c, 6, danger);
    fill(c + 1, 6, danger);
    fill(c + 2, 6, danger);
    fill(c + 1, 7, danger);
  }

  void _miniStar(void Function(int, int, Color, {double ox, double oy}) fill,
      int c) {
    fill(c + 1, 5, accent);
    fill(c, 6, accent);
    fill(c + 1, 6, accent);
    fill(c + 2, 6, accent);
    fill(c + 1, 7, accent);
  }

  void _miniX(void Function(int, int, Color, {double ox, double oy}) fill,
      int c) {
    fill(c, 5, accent);
    fill(c + 2, 5, accent);
    fill(c + 1, 6, accent);
    fill(c, 7, accent);
    fill(c + 2, 7, accent);
  }

  // Mood-driven face (default), incl. autonomous look/yawn.
  void _paintMoodFace(
      void Function(int, int, Color, {double ox, double oy}) fill) {
    final blinking = t > 0.90 && t < 0.965;
    final yawning = action == _Act.yawn;
    final closed = mood == MascotMood.sleepy || blinking || yawning;
    double eyeDx = 0;
    // action look shifts eyes; approximate cell offset via ox in px handled by
    // caller's cell — here we just nudge columns for clarity.
    const l = 4, r = 10, top = 6;

    if (action == _Act.lookLeft) eyeDx = -1;
    if (action == _Act.lookRight) eyeDx = 1;

    if (closed) {
      for (final ex in [l, r]) {
        fill(ex, top + 1, accent);
        fill(ex + 1, top + 1, accent);
      }
    } else {
      for (final ex in [l, r]) {
        final e = ex + eyeDx.toInt();
        fill(e, top, accent);
        fill(e + 1, top, accent);
        fill(e, top + 1, accent);
        fill(e + 1, top + 1, accent);
      }
      if (mood == MascotMood.worried) {
        fill(l + 1, top - 1, body);
        fill(r, top - 1, body);
      }
    }

    if (yawning) {
      fill(7, 9, danger.withValues(alpha: 0.65));
      fill(8, 9, danger.withValues(alpha: 0.65));
      fill(7, 10, danger.withValues(alpha: 0.65));
      fill(8, 10, danger.withValues(alpha: 0.65));
      return;
    }

    switch (mood) {
      case MascotMood.happy:
        fill(6, 9, accent);
        fill(7, 10, accent);
        fill(8, 10, accent);
        fill(9, 9, accent);
        fill(3, 8, accent.withValues(alpha: 0.35));
        fill(12, 8, accent.withValues(alpha: 0.35));
        break;
      case MascotMood.content:
        fill(7, 9, accent);
        fill(8, 9, accent);
        break;
      case MascotMood.worried:
        fill(6, 10, danger.withValues(alpha: 0.85));
        fill(7, 9, danger.withValues(alpha: 0.85));
        fill(8, 9, danger.withValues(alpha: 0.85));
        fill(9, 10, danger.withValues(alpha: 0.85));
        break;
      case MascotMood.sleepy:
        fill(7, 9, accent.withValues(alpha: 0.6));
        break;
    }
  }

  void _paintParticles(Canvas canvas, Size size, double cell) {
    if (mood == MascotMood.sleepy && face == MascotFace.none) {
      _drawZ(canvas, size, cell);
    }
    if (reactionProgress <= 0) return;
    final p = reactionProgress;
    final rise = (1 - p) * cell * 4;
    final fade = (1 - p).clamp(0.0, 1.0);

    switch (reaction) {
      case MascotReaction.pet:
        _drawHeart(canvas, cell, size.width * 0.28,
            size.height * 0.15 - rise, danger.withValues(alpha: fade));
        _drawHeart(canvas, cell, size.width * 0.60,
            size.height * 0.08 - rise * 1.25, danger.withValues(alpha: fade));
        _drawHeart(canvas, cell, size.width * 0.45,
            size.height * 0.20 - rise * 0.8, danger.withValues(alpha: fade * 0.8));
        break;
      case MascotReaction.income:
      case MascotReaction.celebrate:
        _drawStar(canvas, cell, size.width * 0.20,
            size.height * 0.18 - rise, accent.withValues(alpha: fade));
        _drawStar(canvas, cell, size.width * 0.72,
            size.height * 0.10 - rise * 1.3, accent.withValues(alpha: fade));
        _drawStar(canvas, cell, size.width * 0.48,
            size.height * 0.03 - rise * 0.8, accent.withValues(alpha: fade));
        break;
      case MascotReaction.expense:
        final drop = p * cell * 3;
        canvas.drawRect(
          Rect.fromLTWH(size.width * 0.5, size.height * 0.35 + drop, cell, cell),
          Paint()
            ..isAntiAlias = false
            ..color = danger.withValues(alpha: fade),
        );
        break;
      case MascotReaction.none:
        break;
    }
  }

  void _drawHeart(Canvas canvas, double cell, double x, double y, Color c) {
    _stamp(canvas, cell, x, y, c, const [
      '.#.#.',
      '#####',
      '#####',
      '.###.',
      '..#..',
    ]);
  }

  void _drawStar(Canvas canvas, double cell, double x, double y, Color c) {
    _stamp(canvas, cell, x, y, c, const ['.#.', '###', '.#.']);
  }

  void _stamp(Canvas canvas, double cell, double x, double y, Color c,
      List<String> pat) {
    final paint = Paint()
      ..isAntiAlias = false
      ..color = c;
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

  void _drawZ(Canvas canvas, Size size, double cell) {
    final float = math.sin(t * math.pi * 2) * cell * 0.4;
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
    tp.paint(canvas, Offset(size.width * 0.72, size.height * 0.04 + float));
  }

  @override
  bool shouldRepaint(covariant _CatPainter old) => true;
}
