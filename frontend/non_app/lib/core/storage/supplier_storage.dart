import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SupplierStorage {
  SupplierStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'selected_supplier';

  final FlutterSecureStorage _storage;

  String? _supplierId;

  String? get supplierId => _supplierId;

  Future<String?> load(String userId) async {
    final raw = await _storage.read(key: _key);
    final parts = raw?.split('|');

    _supplierId = parts != null && parts.length == 2 && parts[0] == userId ? parts[1] : null;

    return _supplierId;
  }

  Future<void> save(String userId, String supplierId) async {
    _supplierId = supplierId;
    await _storage.write(key: _key, value: '$userId|$supplierId');
  }

  Future<void> clear() async {
    _supplierId = null;
    await _storage.delete(key: _key);
  }
}