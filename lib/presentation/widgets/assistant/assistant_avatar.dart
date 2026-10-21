import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Visuel de l'assistant, réutilisé partout (bouton flottant, en-tête du
/// panneau, bulles). Le visuel définitif remplacera simplement l'asset.
class AssistantAvatar extends StatelessWidget {
  static const String asset = 'assets/images/assistant/avatar.svg';

  final double size;

  const AssistantAvatar({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SvgPicture.asset(asset, width: size, height: size),
    );
  }
}
