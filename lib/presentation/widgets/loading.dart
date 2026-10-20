import 'package:flutter/material.dart';

class LoadingDialog extends StatelessWidget {
  final String loadingText;

  const LoadingDialog({Key? key, required this.loadingText}) : super(key: key);

  /// Affiche le dialogue (non refermable) pendant [task], puis le ferme, que
  /// la tâche réussisse ou non.
  static Future<T> run<T>(
      BuildContext context, String loadingText, Future<T> Function() task) async {
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
          canPop: false, child: LoadingDialog(loadingText: loadingText)),
    );
    try {
      return await task();
    } finally {
      navigator.pop();
    }
  }

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