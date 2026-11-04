import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo Tribuneo (assets/svg/logo_tribuneo.svg) dont la partie navy passe en
/// [ink] : blanc sur le menu foncé, navy sur fond clair.
class ArcWordmark extends StatelessWidget {
  final double height;
  final Color ink;
  const ArcWordmark({super.key, this.height = 26, this.ink = Colors.white});

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  @override
  Widget build(BuildContext context) {
    final String n = _hex(ink);
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 771.33 174.54">'
      '<path d="m108.52,18.28c0,10.05-8.23,18.28-18.51,18.28h-17.59v114.23c0,10.05-8.23,18.28-18.05,18.28s-18.28-8.23-18.28-18.28V36.56h-17.59C8.22,36.56,0,28.33,0,18.28S8.22,0,18.51,0h71.51c10.28,0,18.51,8.23,18.51,18.28Z" fill="$n"/>'
      '<path d="m159.23,73.11c-.46,10.05-9.14,17.13-19.19,17.37-8,.23-14.62,6.17-14.62,13.93v46.61c0,10.05-8,18.05-18.05,18.05s-18.05-8-18.05-18.050v-79.05c0-9.37,7.54-17.14,17.14-17.14,4.34,0,8.23,1.6,11.42,4.34,9.37-4.8,19.65-5.03,24.22-5.03,10.05.23,17.59,8.91,17.13,18.96Z" fill="$n"/>'
      '<path d="m186.31,169.07c-10.05,0-18.28-8.23-18.28-18.28v-79.05c0-10.05,8.23-18.28,18.28-18.28s18.28,8.22,18.28,18.28v79.05c0,10.05-8.22,18.28-18.28,18.28Zm15.53-136.4c0,8.68-7.08,15.76-15.53,15.76s-15.77-7.08-15.77-15.76,7.08-15.54,15.77-15.54,15.53,7.08,15.53,15.54Z" fill="$n"/>'
      '<path d="m334.93,110.58c0,32.21-26.27,58.49-58.49,58.49-10.28,0-20.1-2.74-28.56-7.31-3.2,3.43-7.54,5.48-12.56,5.48-9.83,0-17.37-7.54-17.37-17.37V34.27c0-9.14,7.77-16.91,16.91-17.13h1.83c9.83,0,17.59,7.99,17.59,18.05v21.25c6.630-2.74,14.39-4.34,22.16-4.34,32.22,0,58.49,26.27,58.49,58.49Zm-36.33,0c0-12.34-10.05-22.16-22.16-22.16s-22.16,9.82-22.16,22.16,10.05,22.16,22.16,22.16,22.16-10.05,22.16-22.16Z" fill="$n"/>'
      '<path d="m626.29,123.83h-60.77c10.05,15.31,29.01,17.59,43.64,9.59,7.31-4.57,16.91-1.82,21.25,5.49,4.34,7.54,1.83,17.13-5.48,21.48-9.82,5.71-21.02,8.68-32.67,8.68-26.27,0-46.84-14.85-55.98-33.82-7.08-14.62-6.85-32.67-.69-47.52,8-19.42,27.88-35.64,53.69-35.64,29.47,0,54.15,21.93,57.8,51.18,1.37,13.71-7.77,20.56-20.79,20.56Zm-13.94-26.05c-2.06-8.68-11.65-16.9-23.3-16.9s-21.25,8.22-23.3,16.9h46.61Z" fill="#f8aa36"/>'
      '<path d="m771.33,110.58c0,32.21-26.27,58.49-58.49,58.49s-58.49-26.27-58.49-58.49,26.27-58.49,58.49-58.49,58.49,26.27,58.49,58.49Zm-80.65,0c0,12.34,9.82,22.16,22.16,22.16s22.16-9.82,22.16-22.16-9.83-22.16-22.16-22.16-22.16,9.82-22.16,22.16Z" fill="#f8aa36"/>'
      '<path d="m361.19,72.95c-.16,11.95-.31,23.97,0,35.92.31,12.63,4.83,24.82,13.55,34.08,17.81,18.92,48.49,19.44,67.21,1.49,10.23-9.81,15.46-23.84,15.39-37.92" fill="none" stroke="$n" stroke-linecap="round" stroke-linejoin="round" stroke-width="34.03"/>'
      '<path d="m506.38,141.4c.16-11.95.31-23.97,0-35.92-.31-12.63-4.83-24.82-13.55-34.08-17.81-18.92-48.49-19.44-67.21-1.49-10.23,9.81-15.46,23.84-15.39,37.92" fill="none" stroke="#f8aa36" stroke-linecap="round" stroke-linejoin="round" stroke-width="34.03"/>'
      '</svg>',
      height: height,
      semanticsLabel: 'Tribuneo',
    );
  }
}

/// Les deux arcs entrelacés du logo, en motif décoratif.
class ArcPicto extends StatelessWidget {
  final double width;
  final Color ink;
  final Color accent;
  const ArcPicto(
      {super.key,
      this.width = 34,
      this.ink = const Color(0xff3A4276),
      this.accent = const Color(0xffF8AA36)});

  @override
  Widget build(BuildContext context) {
    final String n = ArcWordmark._hex(ink), o = ArcWordmark._hex(accent);
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 538.51 404.05">'
      '<path d="m51.56,99.39c-.47,35.83-.91,71.89-.03,107.71.94,37.89,14.49,74.43,40.64,102.21,53.42,56.73,145.42,58.3,201.55,4.47,30.66-29.41,46.36-71.5,46.14-113.73" fill="none" stroke="$n" stroke-linecap="round" stroke-linejoin="round" stroke-width="102.04"/>'
      '<path d="m486.95,304.66c.47-35.83.91-71.89.03-107.71-.94-37.89-14.49-74.43-40.64-102.21-53.42-56.73-145.42-58.3-201.55-4.47-30.66,29.41-46.36,71.5-46.14,113.73" fill="none" stroke="$o" stroke-linecap="round" stroke-linejoin="round" stroke-width="102.04"/>'
      '</svg>',
      width: width,
      excludeFromSemantics: true,
    );
  }
}
