import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum TribuneoMascotMood { welcome, idle, thinking }

/// Version Flutter de la mascotte Remotion : logo, yeux et une main à cinq doigts.
/// Le coucou se joue une fois à l'apparition, puis laisse place au repos.
class TribuneoMascot extends StatefulWidget {
  final double width;
  final TribuneoMascotMood mood;
  final bool animate;
  final bool showHand;

  const TribuneoMascot({
    super.key,
    this.width = 240,
    this.mood = TribuneoMascotMood.idle,
    this.animate = true,
    this.showHand = true,
  });

  @override
  State<TribuneoMascot> createState() => _TribuneoMascotState();
}

class _TribuneoMascotState extends State<TribuneoMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  void _syncAnimation() {
    if (widget.animate && !MediaQuery.disableAnimationsOf(context)) {
      if (!_clock.isAnimating) _clock.repeat();
    } else {
      _clock.stop();
      _clock.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant TribuneoMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) _clock.reset();
    _syncAnimation();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox(
            width: widget.width,
            height: widget.width * 600 / 720,
            child: FittedBox(
              child: AnimatedBuilder(
                animation: _clock,
                builder: (context, _) {
                  final t = _clock.value * 6;
                  final elapsed =
                      (_clock.lastElapsedDuration?.inMicroseconds ?? 0) /
                          Duration.microsecondsPerSecond;
                  final thinking = widget.mood == TribuneoMascotMood.thinking;
                  final greeting = widget.mood == TribuneoMascotMood.welcome;
                  final moving = widget.animate &&
                      !MediaQuery.disableAnimationsOf(context);
                  final bob = moving ? math.sin(t * math.pi / 3) * 5 : 0.0;
                  final blink = moving
                      ? (1 - (1 - (t - 3.7).abs() / .12).clamp(0.0, 1.0))
                          .clamp(.08, 1.0)
                      : 1.0;
                  final welcome = greeting && elapsed < 2.5;
                  final settle = ((elapsed - 2) / .5).clamp(0.0, 1.0);
                  final wave = moving && welcome
                      ? math.sin(elapsed * math.pi * 4) *
                          18 *
                          math.pow(
                              math.sin(math.pi * (elapsed / 2).clamp(0.0, 1.0)),
                              2)
                      : 0.0;
                  return SizedBox(
                    width: 720,
                    height: 600,
                    child: Stack(children: [
                      Positioned(
                        left: 275 - bob,
                        top: 434,
                        child: Container(
                          width: 170 + bob * 2,
                          height: 22,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xff3a4276).withValues(alpha: .08),
                            borderRadius: BorderRadius.all(
                              Radius.elliptical(85 + bob, 11),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 210,
                        top: 172.5 + bob,
                        child: SvgPicture.asset(
                          'assets/images/assistant/tribuneo_logo.svg',
                          width: 300,
                          height: 225,
                        ),
                      ),
                      Positioned(
                        left: 301,
                        top: 223 + bob,
                        child: Transform.rotate(
                          angle: (thinking
                                  ? -5
                                  : moving
                                      ? math.sin(t * math.pi / 3) * 2
                                      : 0) *
                              math.pi /
                              180,
                          child: CustomPaint(
                            size: const Size(128, 94),
                            painter: _EyesPainter(
                              blink: blink,
                              look: thinking
                                  ? -5
                                  : moving
                                      ? math.sin(t * math.pi / 3) * 2
                                      : 0,
                              thinking: thinking,
                            ),
                          ),
                        ),
                      ),
                      if (widget.showHand)
                        Positioned(
                          left: (thinking ? 442.0 : 545.0) - 60,
                          top: (thinking
                                  ? 345
                                  : welcome
                                      ? 238 + 107 * settle
                                      : 345) +
                              bob -
                              70,
                          child: Transform.rotate(
                            alignment: const Alignment(0, 1.0 / 6),
                            angle: (thinking ? -30 : 12 + wave) * math.pi / 180,
                            child: SvgPicture.string(_glove,
                                width: 120, height: 120),
                          ),
                        ),
                      if (thinking)
                        for (var i = 0; i < 3; i++)
                          Positioned(
                            left: 441 + i * 27,
                            top: 147 +
                                bob -
                                (moving
                                    ? math.sin(t * math.pi * 2 - i * .8) * 5
                                    : 0),
                            child: Opacity(
                              opacity: moving
                                  ? .35 +
                                      .6 *
                                          (.5 +
                                              .5 *
                                                  math.sin(
                                                      t * math.pi * 2 - i * .8))
                                  : .65,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                    color: Color(0xff3a4276),
                                    shape: BoxShape.circle),
                              ),
                            ),
                          ),
                    ]),
                  );
                },
              ),
            ),
          ),
        ),
      );
}

class _EyesPainter extends CustomPainter {
  final double blink;
  final double look;
  final bool thinking;

  const _EyesPainter(
      {required this.blink, required this.look, required this.thinking});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(64, 47);
    canvas.scale(1, blink);
    for (final (x, y) in [(-28.0, 0.0), (26.0, -3.0)]) {
      final eye = Rect.fromCenter(center: Offset(x, y), width: 48, height: 64);
      canvas.drawOval(eye, Paint()..color = Colors.white);
      canvas.drawOval(
          eye,
          Paint()
            ..color = const Color(0xff3a4276)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x + 3 + look, y + (thinking ? -7 : 4)),
              width: 20,
              height: 30),
          Paint()..color = const Color(0xff24294b));
      canvas.drawCircle(
          Offset(x + 6 + look, y - 2), 3.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _EyesPainter oldDelegate) =>
      blink != oldDelegate.blink ||
      look != oldDelegate.look ||
      thinking != oldDelegate.thinking;
}

const _glove =
    '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="-60 -70 120 120">
<path d="M-18 27 C-24 22-28 12-34 4 L-44-10 C-51-20-40-29-33-21 L-22-9 L-25-36 C-26-50-10-52-9-38 L-7-18 L-6-48 C-6-62 10-62 10-48 L11-18 L16-40 C19-53 34-49 31-36 L27-11 L35-27 C41-39 54-31 48-19 L39 5 Q34 20 24 26 Q20 30 13 29 Z" fill="white" stroke="#3a4276" stroke-width="3.5" stroke-linejoin="round"/>
<path d="M-17 22 Q-2 28 17 23 M-23-8 Q-7-12-4 3" fill="none" stroke="#d9dcec" stroke-width="3.5" stroke-linecap="round"/>
</svg>''';
