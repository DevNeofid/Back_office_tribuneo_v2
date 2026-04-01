import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tribuneo_backoffice/presentation/utils/common.dart';
import 'package:tribuneo_backoffice/env/env.dart';

class Header extends StatelessWidget {
  const Header({
    Key? key,
    this.title = 'Dashboard',
  }) : super(key: key);

  final String title;

  Future<void> _signOut() async {
    final tokenBox = await Hive.openBox('token');
    await tokenBox.delete('token');
  }

  void _signOutAndNavigateToLogin(BuildContext context) async {
    await _signOut();
    // ignore: use_build_context_synchronously
    _navigateToLogin(context);
  }

  void _showPopupMenu(BuildContext context, GlobalKey buttonKey) {
    final RenderBox? button =
        buttonKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button!.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay!.size,
    );

    showMenu(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(
          value: 'sign_out',
          child: Text('Déconnexion'),
        ),
      ],
    ).then((value) {
      if (value == 'sign_out') {
        _signOutAndNavigateToLogin(context);
      }
    });
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final buttonKey = GlobalKey();

    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              title,
              style: GoogleFonts.poppins(
                  fontSize: 30,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w800,
                  color: kBlueEnd),
            ),
            SelectableText(
              "Tribuneo Backoffice ",
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w400,
                  color: kBlueEnd),
            ),
          ],
        ),
      ),
      const Spacer(
        flex: 1,
      ),
      TextButton(
        key: buttonKey,
        onPressed: () {
          _showPopupMenu(context, buttonKey);
        },
        child: RichText(
          text: TextSpan(
            children: [
              WidgetSpan(
                child: Icon(Icons.person, size: 25, color: kBlue),
              ),
              TextSpan(
                text: Env.kNetworkName,
                style: TextStyle(
                  fontSize: 25,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w400,
                  color: kBlue,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}
