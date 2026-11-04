import 'dart:convert';

import 'package:back_office_tribuneo_v2/data/local/storage_model.dart';
import 'package:back_office_tribuneo_v2/data/local/storage_service.dart';

/// Filtre, recherche et page de la grille d'import, mémorisés sur le poste
/// par réseau et par lot : on retrouve sa place en revenant sur un lot.
abstract class MerchantImportViewStore {
  Future<Map<String, dynamic>?> read(int batchId);
  Future<void> save(int batchId, Map<String, dynamic> state);
}

class SecureMerchantImportViewStore implements MerchantImportViewStore {
  final StorageService _storage = StorageService();

  /// Les numéros de lot sont propres à chaque réseau.
  Future<String> _key(int batchId) async {
    final String network = await _storage.readSecureData('id_network') ?? '';
    return 'merchant_import_view_${network}_$batchId';
  }

  @override
  Future<Map<String, dynamic>?> read(int batchId) async {
    final String? raw = await _storage.readSecureData(await _key(batchId));
    if (raw == null || raw.isEmpty) return null;
    final dynamic decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  @override
  Future<void> save(int batchId, Map<String, dynamic> state) async {
    await _storage
        .writeSecureData(StorageItem(await _key(batchId), jsonEncode(state)));
  }
}
