import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';

/// Bouton d'une action assistée par l'IA (Néo) : icône « étincelles » et
/// bordure arc-en-ciel qui tourne et s'illumine au survol.
///
/// L'animation suit le réglage « réduire les animations » du système. Le
/// bouton reste un [OutlinedButton] (accessibilité, clavier, tests).
class NeoAiButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;

  const NeoAiButton({super.key, required this.label, this.onPressed});

  /// Dégradé de la bordure et de l'icône.
  static const List<Color> rainbow = [
    Color(0xff7C4DFF),
    Color(0xff2979FF),
    Color(0xff00BFA5),
    Color(0xffFFC400),
    Color(0xffFF6D00),
    Color(0xffF50057),
    Color(0xff7C4DFF),
  ];

  @override
  State<NeoAiButton> createState() => _NeoAiButtonState();
}

class _NeoAiButtonState extends State<NeoAiButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400));
  bool _hovering = false;

  bool get _enabled => widget.onPressed != null;

  void _setHovering(bool hovering) {
    if (_hovering == hovering) return;
    setState(() => _hovering = hovering);
    if (hovering && _enabled && !MediaQuery.of(context).disableAnimations) {
      _spin.repeat();
    } else {
      _spin.stop();
    }
  }

  @override
  void didUpdateWidget(covariant NeoAiButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) _spin.stop();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool lit = _hovering && _enabled;
    return MouseRegion(
      onEnter: (_) => _setHovering(true),
      onExit: (_) => _setHovering(false),
      child: AnimatedBuilder(
        animation: _spin,
        builder: (context, child) => Container(
          key: const ValueKey('neo-ai-ring'),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: _enabled ? null : kNavy200,
            gradient: _enabled
                ? SweepGradient(
                    colors: NeoAiButton.rainbow,
                    transform: GradientRotation(_spin.value * 2 * math.pi))
                : null,
            boxShadow: lit
                ? [
                    BoxShadow(
                        color: NeoAiButton.rainbow[0].withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: 1),
                  ]
                : null,
          ),
          child: child,
        ),
        child: OutlinedButton.icon(
          // Fond blanc pur et texte Navy 800 (design system « Arc »).
          style: OutlinedButton.styleFrom(
            backgroundColor: kSurface,
            foregroundColor: kNavy800,
            disabledBackgroundColor: kNavy50,
            disabledForegroundColor: kNavy400,
            side: BorderSide.none,
            shape: const StadiumBorder(),
            minimumSize: const Size(48, 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onPressed: widget.onPressed,
          icon: _enabled
              ? ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) =>
                      const LinearGradient(colors: NeoAiButton.rainbow)
                          .createShader(bounds),
                  child: const Icon(Icons.auto_awesome, size: 18),
                )
              : const Icon(Icons.auto_awesome, size: 18),
          label: Text(widget.label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
