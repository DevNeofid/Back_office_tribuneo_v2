import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/data/local/storage_function.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/views/my_single_page.dart';

class DashboardContentView extends StatefulWidget {
  const DashboardContentView({super.key});

  @override
  State<DashboardContentView> createState() => _DashboardContentViewState();
}

class _DashboardContentViewState extends State<DashboardContentView> {
  final Completer<void> signOutCompleter = Completer();
  final StorageFunction _storageFunction = StorageFunction();
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
  }

  void callBackMenu(int indexContent) {
    final mySinglePageState = MySinglePage.of(context);
    mySinglePageState.callBackMenu(indexContent);
  }

  Future<void> _signOut() async {
    await _storageFunction.clearUser();
  }

  void _signOutAndNavigateToLogin(BuildContext context) async {
    await _signOut();
    _navigateToLogin(context);
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (signOutCompleter.isCompleted) {
      _navigateToLogin(context);
    }
    return SizedBox(
      width: SizeConfig.screenWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: 'Bienvenue sur votre espace de gestion',
                    style: GoogleFonts.poppins(
                      fontSize: 38,
                      fontWeight: FontWeight.w500,
                      color: kGrey,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.only(
                      top: 12, bottom: 0, left: 0, right: 0),
                  child: SvgPicture.asset(
                    'assets/svg/logo_tribuneo.svg',
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    width: 140,
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 60),
          // insert image bandeaux_horizontal here
          SvgPicture.asset(
            'assets/svg/bandeau_horizontale.svg',
            height: 120,
            width: 150,
          ),
          const SizedBox(height: 70),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.spaceBetween,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hoveredIndex = 0),
                onExit: (_) => setState(() => _hoveredIndex = null),
                child: GestureDetector(
                  child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      height: 150,
                      width: 180,
                      padding: const EdgeInsets.all(20),
                      transform: Matrix4.identity()
                        ..scaleByDouble(_hoveredIndex == 0 ? 1.03 : 1.0, _hoveredIndex == 0 ? 1.03 : 1.0, 1.0, 1.0),
                      decoration: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: kGrey.withValues(
                                alpha: _hoveredIndex == 0 ? 0.2 : 0.1),
                            spreadRadius: _hoveredIndex == 0 ? 3 : 2,
                            blurRadius: _hoveredIndex == 0 ? 14 : 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 25,
                            width: 25,
                            child: Icon(
                              Icons.list_alt,
                              color: kOrange,
                              size: 25,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Commandes',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: kGrey,
                            ),
                          ),
                        ],
                      )),
                  onTap: () {
                    callBackMenu(2);
                  },
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hoveredIndex = 1),
                onExit: (_) => setState(() => _hoveredIndex = null),
                child: GestureDetector(
                  child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      height: 150,
                      width: 180,
                      padding: const EdgeInsets.all(20),
                      transform: Matrix4.identity()
                        ..scaleByDouble(_hoveredIndex == 1 ? 1.03 : 1.0, _hoveredIndex == 1 ? 1.03 : 1.0, 1.0, 1.0),
                      decoration: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: kGrey.withValues(
                                alpha: _hoveredIndex == 1 ? 0.2 : 0.1),
                            spreadRadius: _hoveredIndex == 1 ? 3 : 2,
                            blurRadius: _hoveredIndex == 1 ? 14 : 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 25,
                            width: 25,
                            child: Icon(
                              Icons.storefront,
                              color: kOrange,
                              size: 25,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Partenaires',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: kGrey,
                            ),
                          ),
                        ],
                      )),
                  onTap: () {
                    callBackMenu(3);
                  },
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hoveredIndex = 2),
                onExit: (_) => setState(() => _hoveredIndex = null),
                child: GestureDetector(
                  child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      height: 150,
                      width: 180,
                      padding: const EdgeInsets.all(20),
                      transform: Matrix4.identity()
                        ..scaleByDouble(_hoveredIndex == 2 ? 1.03 : 1.0, _hoveredIndex == 2 ? 1.03 : 1.0, 1.0, 1.0),
                      decoration: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: kGrey.withValues(
                                alpha: _hoveredIndex == 2 ? 0.2 : 0.1),
                            spreadRadius: _hoveredIndex == 2 ? 3 : 2,
                            blurRadius: _hoveredIndex == 2 ? 14 : 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 25,
                            width: 25,
                            child: Icon(
                              Icons.people,
                              color: kOrange,
                              size: 25,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Clients',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: kGrey,
                            ),
                          ),
                        ],
                      )),
                  onTap: () {
                    callBackMenu(1);
                  },
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hoveredIndex = 3),
                onExit: (_) => setState(() => _hoveredIndex = null),
                child: GestureDetector(
                  child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      height: 150,
                      width: 180,
                      padding: const EdgeInsets.all(20),
                      transform: Matrix4.identity()
                        ..scaleByDouble(_hoveredIndex == 3 ? 1.03 : 1.0, _hoveredIndex == 3 ? 1.03 : 1.0, 1.0, 1.0),
                      decoration: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: kGrey.withValues(
                                alpha: _hoveredIndex == 3 ? 0.2 : 0.1),
                            spreadRadius: _hoveredIndex == 3 ? 3 : 2,
                            blurRadius: _hoveredIndex == 3 ? 14 : 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 25,
                            width: 25,
                            child: Icon(
                              Icons.logout,
                              color: kOrange,
                              size: 25,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Deconnexion',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: kGrey,
                            ),
                          ),
                        ],
                      )),
                  onTap: () {
                    _signOutAndNavigateToLogin(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
