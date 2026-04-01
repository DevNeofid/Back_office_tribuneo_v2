import 'package:tribuneo_backoffice/domain/repositories/main_repository.dart';

class MainUseCase {
  final MainRepository mainRepository = MainRepository();

  // Function for adding a new order
  Future<void> syncData() async {
    return await mainRepository.syncData();
  }

  Future<bool> authCheck(String token) async {
    return await mainRepository.authCheck(token);
  }
}