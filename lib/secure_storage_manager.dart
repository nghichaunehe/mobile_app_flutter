// secure_storage_manager.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageManager {
  // Tạo instance (thêm cấu hình cho Android để tránh lỗi mã hóa)
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyJwt = 'jwt_token';

  /// Lưu trữ JWT
  static Future<void> saveJwt(String token) async {
    try {
      await _storage.write(key: _keyJwt, value: token);
    } catch (e) {
      print("Lỗi khi lưu token: $e");
    }
  }

  /// Đọc JWT
  static Future<String?> getJwt() async {
    try {
      return await _storage.read(key: _keyJwt);
    } catch (e) {
      print("Lỗi khi đọc token: $e");
      return null;
    }
  }

  /// Xóa JWT (Đăng xuất)
  static Future<void> deleteJwt() async {
    try {
      await _storage.delete(key: _keyJwt);
      print("Đã xóa token thành công");
    } catch (e) {
      print("Lỗi khi xóa token: $e");
    }
  }
}