import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/domain/models/result.dart';

abstract class BaseStatefulWidget<T extends StatefulWidget> extends State<T> {
  void onDataReceived(dynamic data);

  Future<void> handleResult<C>(
    Future<Result<C>> resultFuture, {
    required void Function(C data) onDataReceived,
    void Function()? onLoading,
    void Function(String error)? onError,
    void Function(String message)? onShowSnackBar,
  }) async {
    try {
      //if (onLoading != null) onLoading();
      Result<C> result = await resultFuture;
      if (result.error) {
        if (onError != null) {
          onError(result.errorMessage!);
        } else if (onShowSnackBar != null) {
          onShowSnackBar(result.errorMessage!);
        }
      } else {
        onDataReceived(result.data as C);
      }
    } catch (e) {
      if (onError != null) {
        onError(e.toString());
      } else if (onShowSnackBar != null) {
        onShowSnackBar(e.toString());
      }
    }
  }
}
