import 'package:back_office_tribuneo_v2/domain/repositories/main_repository.dart';

class MainUseCase {
  final MainRepository _mainRepository = MainRepository();

  Future<bool> checkToken() async {
    return await _mainRepository.checkToken();
  }
}
