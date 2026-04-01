import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';

class TabControllerProvider with ChangeNotifier {
  TabControllerProvider({required this.initialIndex});


  int initialIndex;
  late TabController tabController;

  void changeTab(int index) {
    tabController.animateTo(index);
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    tabController.dispose();
  }
}
