import 'package:flutter/material.dart';

class LoadingDialog extends StatelessWidget {
  final String loadingText;

  const LoadingDialog({Key? key, required this.loadingText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Text(loadingText),
        ],
      ),
    );
  }
}