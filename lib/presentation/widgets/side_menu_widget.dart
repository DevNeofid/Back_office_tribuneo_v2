// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';

// import 'package:tribuneo_backoffice/config/size_config.dart';
// import 'package:tribuneo_backoffice/presentation/utils/common.dart';

// class SideMenu extends StatelessWidget {
//   final String contentName;
//   final Function(String) callback;

//   const SideMenu({
//     Key? key,
//     required this.contentName,
//     required this.callback,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     if (kDebugMode) {
//       print("###DEBUG### SIDE MENU BUILDER: ");
//       print("###DEBUG### - contentName : $contentName}");
//     }

//     SizeConfig().init(context);
//     return Drawer(
//       elevation: 0,
//       child: Container(
//         width: double.infinity,
//         height: SizeConfig.screenHeight,
//         decoration: const BoxDecoration(color: kPLGrey2),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Container(
//                 height: 100,
//                 alignment: Alignment.topCenter,
//                 width: double.infinity,
//                 padding: const EdgeInsets.only(
//                     top: 20, bottom: 10, left: 20, right: 20),
//                 child: Container(
//                   decoration: const BoxDecoration(
//                     image: DecorationImage(
//                       image: AssetImage("assets/png/icon_app_neomy.png"),
//                       fit: BoxFit.contain,
//                       alignment: Alignment.center,
//                     ),
//                   ),
//                 ),
//               ),
//               // Home Icon Menu
//               IconButton(
//                 iconSize: 30,
//                 padding: const EdgeInsets.symmetric(vertical: 20.0),
//                 icon: Icon(Icons.home,
//                     color: contentName == 'dashboard' ? kBlue : kLBlue),
//                 onPressed: () {
//                   if (kDebugMode) {
//                     print("Menu Home");
//                   }
//                   callback('dashboard');
//                 },
//               ),
//               // Sponsor Icon Menu
//               IconButton(
//                 iconSize: 30,
//                 padding: const EdgeInsets.symmetric(vertical: 20.0),
//                 icon: Icon(
//                   Icons.list_alt,
//                   color: (contentName == 'orders') ? kBlue : kLBlue,
//                 ),
//                 onPressed: () {
//                   if (kDebugMode) {
//                     print("Menu Sponsor (commanditaire)");
//                   }
//                   callback('orders');
//                 },
//               ),
//               // Partner Icon Menu
//               IconButton(
//                 iconSize: 30,
//                 padding: const EdgeInsets.symmetric(vertical: 20.0),
//                 icon: Icon(Icons.storefront,
//                     color: contentName == 'partners' ? kBlue : kLBlue),
//                 onPressed: () {
//                   if (kDebugMode) {
//                     print("Menu Partner");
//                   }
//                 },
//               ),
//               // Customer Icon Menu
//               IconButton(
//                 iconSize: 30,
//                 padding: const EdgeInsets.symmetric(vertical: 20.0),
//                 icon: Icon(Icons.storefront,
//                     color: contentName == 'customers' ? kBlue : kLBlue),
//                 onPressed: () {
//                   if (kDebugMode) {
//                     print("Menu Customer");
//                   }
//                 },
//               ),
//               // Stats/Export Icon Menu
//               IconButton(
//                 iconSize: 30,
//                 padding: const EdgeInsets.symmetric(vertical: 20.0),
//                 icon: Icon(Icons.analytics,
//                     color: contentName == 'export' ? kBlue : kLBlue),
//                 onPressed: () {
//                   if (kDebugMode) {
//                     print("Menu Stats/Export");
//                   }
//                 },
//               ),
//               // QR-code Icon Menu
//               IconButton(
//                 iconSize: 30,
//                 padding: const EdgeInsets.symmetric(vertical: 20.0),
//                 icon: Icon(Icons.qr_code_2,
//                     color: contentName == 'qrcode' ? kBlue : kLBlue),
//                 onPressed: () {
//                   if (kDebugMode) {
//                     print("Menu QR-code");
//                   }
//                 },
//               ),
//               // Settings Icon Menu
//               IconButton(
//                 iconSize: 30,
//                 padding: const EdgeInsets.symmetric(vertical: 20.0),
//                 icon: Icon(Icons.settings,
//                     color: contentName == 'settings' ? kBlue : kLBlue),
//                 onPressed: () {
//                   if (kDebugMode) {
//                     print("Menu settings");
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
