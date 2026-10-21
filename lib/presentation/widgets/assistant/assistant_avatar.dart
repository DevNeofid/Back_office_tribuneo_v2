import 'package:flutter/material.dart';
import 'tribuneo_mascot.dart';

/// Visuel de l'assistant, réutilisé partout (bouton flottant, en-tête du
/// panneau, bulles). Version fixe pour garder les petits avatars discrets.
class AssistantAvatar extends StatelessWidget {
  final double size;

  const AssistantAvatar({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: FittedBox(
              child: SizedBox.square(
                dimension: 480,
                child: Stack(
                  children: const [
                    Positioned(
                      left: -120,
                      top: -60,
                      child: TribuneoMascot(
                          width: 720, animate: false, showHand: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
