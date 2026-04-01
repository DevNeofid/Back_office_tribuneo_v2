import 'package:flutter/material.dart';
import 'package:tribuneo_backoffice/config/size_config.dart';


class ComingSoonView extends StatelessWidget {
  const ComingSoonView({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: SizeConfig.screenWidth,
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.access_time,
              size: 100.0,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 20.0),
            const SelectableText(
              'Coming Soon',
              style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            const SelectableText(
              'We are working hard to bring you an amazing experience. Stay tuned!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.0),
            ),
          ],
        ),
    );
  }
}
