import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Loader Tribuneo : aller-retour continu, cycle de 4 s (vitesse validée ×1,2).
/// Les tracés et les couleurs sont ceux de Picto_Tribuneo_rvb.svg.
class TribuneoLoader extends StatefulWidget {
  const TribuneoLoader({
    super.key,
    this.size = 40,
    this.semanticLabel = 'Chargement',
    this.animate = true,
  }) : assert(size > 0);

  final double size;
  final String semanticLabel;
  final bool animate;

  @override
  State<TribuneoLoader> createState() => _TribuneoLoaderState();
}

class _TribuneoLoaderState extends State<TribuneoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant TribuneoLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) _syncAnimation();
  }

  void _syncAnimation() {
    _reduceMotion = !widget.animate ||
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    if (_reduceMotion) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: widget.semanticLabel,
        child: SizedBox.square(
          dimension: widget.size,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _TribuneoLoaderPainter(_clock, _reduceMotion),
            ),
          ),
        ),
      );
}

/// Remplace une attente linéaire par le logo, en conservant le pourcentage
/// lorsque la tâche fournit une progression réelle.
class TribuneoLoadingProgress extends StatelessWidget {
  const TribuneoLoadingProgress({super.key, this.value, this.animate = true});

  final double? value;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final percent =
        value == null ? null : (value!.clamp(0.0, 1.0) * 100).round();
    return Semantics(
      label: animate ? 'Chargement' : 'Progression',
      value: percent == null ? null : '$percent %',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            TribuneoLoader(size: 24, animate: animate),
            if (percent != null) ...[
              const SizedBox(width: 8),
              Text(
                '$percent %',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TribuneoLoaderPainter extends CustomPainter {
  _TribuneoLoaderPainter(this.clock, this.reduceMotion) : super(repaint: clock);

  final Animation<double> clock;
  final bool reduceMotion;
  static const _viewBox = Size(538.51, 404.05);
  static const _strokeWidth = 102.04;
  static const _navy = Color(0xff3a4276);
  static const _orange = Color(0xfff7a935);

  // Commandes cubiques relatives du SVG original, sans approximation.
  static final _blue = (Path()
        ..moveTo(51.56, 99.39)
        ..relativeCubicTo(-.47, 35.83, -.91, 71.89, -.03, 107.71)
        ..relativeCubicTo(.94, 37.89, 14.49, 74.43, 40.64, 102.21)
        ..relativeCubicTo(53.42, 56.73, 145.42, 58.3, 201.55, 4.47)
        ..relativeCubicTo(30.66, -29.41, 46.36, -71.5, 46.14, -113.73))
      .computeMetrics()
      .first;
  static final _amber = (Path()
        ..moveTo(486.95, 304.66)
        ..relativeCubicTo(.47, -35.83, .91, -71.89, .03, -107.71)
        ..relativeCubicTo(-.94, -37.89, -14.49, -74.43, -40.64, -102.21)
        ..relativeCubicTo(-53.42, -56.73, -145.42, -58.3, -201.55, -4.47)
        ..relativeCubicTo(-30.66, 29.41, -46.36, 71.5, -46.14, 113.73))
      .computeMetrics()
      .first;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = math.min(
      size.width / _viewBox.width,
      size.height / _viewBox.height,
    );
    canvas.save();
    canvas.translate(
      (size.width - _viewBox.width * scale) / 2,
      (size.height - _viewBox.height * scale) / 2,
    );
    canvas.scale(scale);
    _drawStroke(canvas, _blue, _navy, clock.value);
    // 66,7 ms sur 4 s : même décalage relatif que la proposition Remotion.
    _drawStroke(canvas, _amber, _orange, clock.value - 1 / 60);
    canvas.restore();
  }

  void _drawStroke(
    Canvas canvas,
    ui.PathMetric metric,
    Color color,
    double phase,
  ) {
    final quarter = (((phase % 1) + 1) % 1) * 4;
    final stage = quarter.floor();
    final progress = (1 - math.cos(math.pi * (quarter - stage))) / 2;
    final double start;
    final double end;
    if (reduceMotion) {
      start = 0;
      end = 1;
    } else if (stage == 0) {
      start = 0;
      end = progress;
    } else if (stage == 1) {
      start = progress;
      end = 1;
    } else if (stage == 2) {
      start = 1 - progress;
      end = 1;
    } else {
      start = 0;
      end = 1 - progress;
    }
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      metric.extractPath(start * metric.length, end * metric.length),
      stroke,
    );
    // Toujours peindre le point : certains moteurs omettent les segments
    // presque nuls juste après le changement de sens.
    final anchor = metric.getTangentForOffset(end == 1 ? metric.length : 0)!;
    canvas.drawCircle(
      anchor.position,
      _strokeWidth / 2,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _TribuneoLoaderPainter oldDelegate) =>
      oldDelegate.clock != clock || oldDelegate.reduceMotion != reduceMotion;
}
