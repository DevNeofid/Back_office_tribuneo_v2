import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tribuneo_backoffice/config/responsive.dart';
import 'package:tribuneo_backoffice/config/size_config.dart';
import 'package:tribuneo_backoffice/presentation/utils/common.dart';

class CardAction extends StatelessWidget {
  final String icon;
  final String label;

  const CardAction({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
          minWidth: Responsive.isDesktop(context)
              ? 200
              : SizeConfig.screenWidth / 2 - 40),
      padding: EdgeInsets.only(
          top: 20,
          bottom: 20,
          left: 20,
          right: Responsive.isMobile(context) ? 20 : 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: kPWhite,
        boxShadow: const [
          BoxShadow(
              color: kNBlue,
              blurRadius: 14,
              spreadRadius: 0,
              offset: Offset(6, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image from icon
          // Image.asset(
          //   icon,
          //   width: 30,
          //   height: 30,
          // ),
          SvgPicture.asset(icon, width: 35),
          SizedBox(
            height: SizeConfig.blockSizeVertical * 2,
          ),
          SelectableText(
            label,
            style: GoogleFonts.poppins(
                fontSize: 16,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w500,
                color: kBlack),
          ),
          SizedBox(
            height: SizeConfig.blockSizeVertical * 2,
          ),
          // SelectableText(
          //   amount,
          //   style: GoogleFonts.poppins(
          //       fontSize: 16,
          //       letterSpacing: 0.3,
          //       fontWeight: FontWeight.w700,
          //       color: kBlack),
          // ),
        ],
      ),
    );
  }
}
