import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_update_results_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/orders_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/formatters.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/loading.dart';

/// Sélecteur de date de validité : minimum demain, aucune date passée possible.
Future<DateTime?> pickExpiryDate(BuildContext context,
    {DateTime? current, String? helpText}) {
  final DateTime minDate = tomorrow();
  DateTime initialDate = current ?? minDate;
  if (initialDate.isBefore(minDate)) initialDate = minDate;

  return showDatePicker(
    builder: (context, child) {
      return Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: kBlue),
        ),
        child: child!,
      );
    },
    helpText: helpText,
    fieldHintText: 'Jour/Mois/Année',
    locale: const Locale('fr', 'FR'),
    context: context,
    initialDate: initialDate,
    firstDate: minDate,
    lastDate: DateTime(3000),
  );
}

/// Change la date de validité de tous les bons de [order] (`PUT
/// /order/{id}/expiry-date`), disponible même après facture.
///
/// Retourne `true` si la date a été mise à jour.
Future<bool> changeOrderExpiryDate(BuildContext context, OrderModel order,
    {OrderUseCase? orderUseCase}) async {
  final DateTime? current =
      DateTime.tryParse(order.fundExpiryDate?.date ?? '');
  final DateTime? selected = await pickExpiryDate(context,
      current: current, helpText: 'Date de validité de toute la commande');
  if (selected == null || !context.mounted) return false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) =>
        const LoadingDialog(loadingText: 'Mise à jour de la date de validité...'),
  );
  OrderExpiryUpdateResult? result;
  String? failure;
  try {
    result = await (orderUseCase ?? OrderUseCase())
        .updateOrderExpiryDate(order.id!, formatApiDate(selected));
  } on ApiException catch (e) {
    failure = e.message;
  } catch (_) {
    failure = 'Erreur lors de la mise à jour de la date de validité.';
  } finally {
    navigatorKey.currentState?.pop();
  }

  if (result == null) {
    snackbarKey.currentState?.showSnackBar(SnackBar(
        content: Text(failure ??
            'Erreur lors de la mise à jour de la date de validité.'),
        backgroundColor: kRed,
        duration: const Duration(seconds: 8)));
    return false;
  }

  snackbarKey.currentState?.showSnackBar(SnackBar(
      content: Text('Date de validité mise à jour pour '
          '${result.vouchersUpdated} bon(s).'),
      backgroundColor: kGreen));
  return true;
}
