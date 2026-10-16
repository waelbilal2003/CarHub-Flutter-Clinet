import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// مسؤول عن حفظ/قراءة/حذف توكن الدخول بشكل مشفّر على الجهاز.
/// يُستخدم من الـ Interceptor (لإضافة التوكن للطلبات) ومن AuthRepository.
class TokenStorage {
  static const _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;

  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> readToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }
}
