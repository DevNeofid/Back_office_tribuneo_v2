import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:back_office_tribuneo_v2/config/responsive.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_avatar.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_controller.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_panel.dart';

const double _margin = 24;
const double _buttonSize = 56;

/// Marge autour du bouton dans laquelle déborde la pastille « masquer » : elle
/// doit rester dans la zone du lanceur pour recevoir les clics.
const double _launcherInset = 8;
const double _tabHeight = 48;

/// Assistant affiché par-dessus le contenu de `MySinglePage` : bouton flottant,
/// languette quand il est caché, panneau de conversation (§ 3 de la spec).
///
/// À placer dans un `Positioned.fill` au-dessus du contenu ; les zones vides
/// laissent passer les clics vers la page.
class AssistantOverlay extends StatefulWidget {
  const AssistantOverlay({super.key});

  @override
  State<AssistantOverlay> createState() => _AssistantOverlayState();
}

class _AssistantOverlayState extends State<AssistantOverlay> {
  /// Brouillon du message, conservé quand le panneau est réduit.
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AssistantController controller = context.watch<AssistantController>();
    if (!controller.ready) return const SizedBox.shrink();

    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    final bool desktop = Responsive.isDesktop(context);

    return LayoutBuilder(builder: (context, constraints) {
      final Widget panelSwitcher = AnimatedSwitcher(
        duration: Duration(milliseconds: reduceMotion ? 150 : 200),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          fit: StackFit.expand,
          children: [...previous, if (current != null) current],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: reduceMotion
              ? child
              : ScaleTransition(
                  scale: animation,
                  alignment: Alignment.bottomRight,
                  child: child,
                ),
        ),
        child: controller.isOpen
            ? AssistantPanel(
                key: const ValueKey('assistant-panel'),
                input: _input,
                fullScreen: !desktop,
              )
            : const SizedBox.shrink(key: ValueKey('assistant-panel-closed')),
      );

      return Stack(
        children: [
          Positioned(
            right: _margin,
            bottom: _margin,
            child: _LauncherButton(
              state: controller.state,
              openedOnce: controller.openedOnce,
              hasUnread: controller.hasUnread,
              replyPulses: controller.replyPulses,
              desktop: desktop,
              onOpen: controller.open,
              onHide: controller.hide,
            ),
          ),
          Positioned(
            right: 0,
            bottom: _margin + (_buttonSize - _tabHeight) / 2,
            child: _LauncherTab(
              visible: controller.state == AssistantLauncherState.hidden,
              hasUnread: controller.hasUnread,
              desktop: desktop,
              onShow: controller.show,
            ),
          ),
          if (desktop)
            Positioned(
              right: _margin,
              bottom: _margin,
              width: math.max(
                  0, math.min(400, constraints.maxWidth - 2 * _margin)),
              height: math.max(
                  0, math.min(600, constraints.maxHeight - 2 * _margin)),
              child: panelSwitcher,
            )
          else
            Positioned.fill(child: panelSwitcher),
        ],
      );
    });
  }
}

/// Bouton flottant, avec sa pastille « masquer », son halo et la pastille de
/// réponse non lue.
class _LauncherButton extends StatefulWidget {
  final AssistantLauncherState state;
  final bool openedOnce;
  final bool hasUnread;
  final int replyPulses;
  final bool desktop;
  final VoidCallback onOpen;
  final VoidCallback onHide;

  const _LauncherButton({
    required this.state,
    required this.openedOnce,
    required this.hasUnread,
    required this.replyPulses,
    required this.desktop,
    required this.onOpen,
    required this.onHide,
  });

  @override
  State<_LauncherButton> createState() => _LauncherButtonState();
}

class _LauncherButtonState extends State<_LauncherButton>
    with TickerProviderStateMixin {
  static const Duration _pulseInterval = Duration(seconds: 30);
  static const int _introPulses = 3;

  /// Entrée à l'apparition. Les contrôleurs ne tournent que pendant leur
  /// animation : pas de boucle infinie, coûteuse en Flutter web.
  late final AnimationController _entry = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));
  Timer? _pulseTimer;
  bool _hovering = false;
  bool _reduceMotion = false;
  bool _started = false;

  bool get _visible => widget.state == AssistantLauncherState.visible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    _entry.duration = Duration(milliseconds: _reduceMotion ? 150 : 600);
    if (!_started && _visible) {
      _started = true;
      _appear();
    }
  }

  @override
  void didUpdateWidget(covariant _LauncherButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool wasHidden = oldWidget.state == AssistantLauncherState.hidden;
    if (_visible && (wasHidden || !_started)) {
      _started = true;
      _appear();
    }
    if (widget.openedOnce && !oldWidget.openedOnce) {
      // Arrêt définitif des pulsations d'attention.
      _pulseTimer?.cancel();
      _pulseTimer = null;
      _pulse.reset();
    }
    if (widget.replyPulses > oldWidget.replyPulses) _pulseOnce();
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _entry.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _appear() async {
    try {
      await _entry.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted || _reduceMotion || widget.openedOnce) return;
    for (int i = 0; i < _introPulses; i++) {
      if (!mounted || !_visible || widget.openedOnce) return;
      try {
        await _pulse.forward(from: 0).orCancel;
      } on TickerCanceled {
        break;
      }
    }
    _pulseTimer ??= Timer.periodic(_pulseInterval, (_) {
      if (_visible && !widget.openedOnce && !_pulse.isAnimating) _pulseOnce();
    });
  }

  void _pulseOnce() {
    if (_reduceMotion || !mounted) return;
    _pulse.forward(from: 0);
  }

  void _setHovering(bool hovering) {
    if (_hovering != hovering) setState(() => _hovering = hovering);
  }

  @override
  Widget build(BuildContext context) {
    final bool hidden = widget.state == AssistantLauncherState.hidden;
    final bool showHideChip = _visible && (!widget.desktop || _hovering);
    final Duration fade = Duration(milliseconds: _reduceMotion ? 150 : 250);

    return IgnorePointer(
      ignoring: !_visible,
      child: AnimatedSlide(
        // Sort par la droite quand il est caché.
        offset: hidden && !_reduceMotion ? const Offset(1.6, 0) : Offset.zero,
        duration: fade,
        curve: Curves.easeInOutCubic,
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: widget.state == AssistantLauncherState.open
              ? const Duration(milliseconds: 150)
              : fade,
          child: MouseRegion(
            onEnter: (_) => _setHovering(true),
            onExit: (_) => _setHovering(false),
            child: SizedBox(
              width: _buttonSize + _launcherInset,
              height: _buttonSize + _launcherInset,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: _buildHalo(),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: _buildButton(),
                  ),
                  if (widget.hasUnread)
                    const Positioned(
                      right: 3,
                      top: 11,
                      child: _UnreadDot(key: ValueKey('assistant-unread')),
                    ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: IgnorePointer(
                      ignoring: !showHideChip,
                      child: AnimatedOpacity(
                        opacity: showHideChip ? 1 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: _buildHideChip(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHalo() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        if (!_pulse.isAnimating) {
          return const SizedBox(width: _buttonSize, height: _buttonSize);
        }
        final double t = _pulse.value;
        return Transform.scale(
          key: const ValueKey('assistant-halo'),
          scale: 1 + 0.6 * t,
          child: Container(
            width: _buttonSize,
            height: _buttonSize,
            decoration: BoxDecoration(
              color: kBlue.withValues(alpha: 0.35 * (1 - t)),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton() {
    final Animation<double> scale = _reduceMotion
        ? const AlwaysStoppedAnimation<double>(1)
        : CurvedAnimation(parent: _entry, curve: Curves.elasticOut);
    return FadeTransition(
      opacity: _reduceMotion ? _entry : const AlwaysStoppedAnimation<double>(1),
      child: ScaleTransition(
        scale: scale,
        child: Tooltip(
          message: 'Assistant Tribuneo',
          // Au-dessus de la pastille « masquer », sinon l'infobulle la couvre
          // au survol et intercepte son clic.
          preferBelow: false,
          verticalOffset: _buttonSize / 2 + _launcherInset + 12,
          child: Material(
            color: kBlue,
            shape: const CircleBorder(),
            elevation: 4,
            shadowColor: kBlack.withValues(alpha: 0.4),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const ValueKey('assistant-launcher'),
              onTap: widget.onOpen,
              child: const SizedBox(
                width: _buttonSize,
                height: _buttonSize,
                child: AssistantAvatar(size: _buttonSize),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHideChip() {
    return Tooltip(
      message: "Masquer l'assistant",
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(side: BorderSide(color: kLBlue)),
        elevation: 1,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onHide,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: Icon(Icons.close, size: 14, color: kBlue),
          ),
        ),
      ),
    );
  }
}

/// Languette collée au bord droit quand l'assistant est caché.
class _LauncherTab extends StatefulWidget {
  final bool visible;
  final bool hasUnread;
  final bool desktop;
  final VoidCallback onShow;

  const _LauncherTab({
    required this.visible,
    required this.hasUnread,
    required this.desktop,
    required this.onShow,
  });

  @override
  State<_LauncherTab> createState() => _LauncherTabState();
}

class _LauncherTabState extends State<_LauncherTab> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool highlighted = widget.desktop && _hovering;
    final Duration duration = Duration(
        milliseconds: MediaQuery.of(context).disableAnimations ? 150 : 250);
    const BorderRadius radius =
        BorderRadius.horizontal(left: Radius.circular(12));

    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: duration,
        child: Tooltip(
          message: "Afficher l'assistant",
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            child: GestureDetector(
              key: const ValueKey('assistant-tab'),
              onTap: widget.onShow,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: highlighted ? 28 : 20,
                    height: _tabHeight,
                    decoration: BoxDecoration(
                      color: kBlue.withValues(alpha: highlighted ? 1 : 0.85),
                      borderRadius: radius,
                    ),
                    child: const Icon(Icons.chevron_left,
                        color: Colors.white, size: 20),
                  ),
                  if (widget.hasUnread)
                    const Positioned(left: -3, top: -3, child: _UnreadDot()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastille `kOrange` : réponse arrivée panneau fermé.
class _UnreadDot extends StatelessWidget {
  const _UnreadDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: kOrange,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}
