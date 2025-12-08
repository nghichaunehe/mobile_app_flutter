// secure_storage_manager.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageManager {
  // Tạo instance của FlutterSecureStorage
  static const _storage = FlutterSecureStorage();

  // Khóa lưu JWT
  static const _keyJwt = 'jwt_token';

  /// Lưu trữ JWT an toàn
  static Future<void> saveJwt(String token) async {
    await _storage.write(key: _keyJwt, value: token);
  }

  /// Đọc JWT
  static Future<String?> getJwt() async {
    return await _storage.read(key: _keyJwt);
  }

  /// Xóa JWT (ví dụ: khi đăng xuất)
  static Future<void> deleteJwt() async {
    await _storage.delete(key: _keyJwt);
  }
}