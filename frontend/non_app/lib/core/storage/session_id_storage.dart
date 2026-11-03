import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionIdStorage {
  SessionIdStorage._();

  static const _storage = FlutterSecureStorage();
  static const _key = 'session_id';

  static Future<String?> read() => _storage.read(key: _key);

  static Future<void> save(String id) => _storage.write(key: _key, value: id);
}