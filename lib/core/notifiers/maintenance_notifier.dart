import 'dart:async';

class MaintenanceNotifier {
  static final _maintenanceController = StreamController<bool>.broadcast();

  static Stream<bool> get onMaintenanceChanged => _maintenanceController.stream;

  static void enterMaintenanceMode() {
    _maintenanceController.sink.add(true);
  }

  static void exitMaintenanceMode() {
    _maintenanceController.sink.add(false);
  }
}
