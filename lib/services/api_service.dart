import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Đổi localhost thành IP máy tính nếu chạy trên Android Emulator (VD: 10.0.2.2)
  final String baseUrl = "https://coral-interjugal-xochitl.ngrok-free.dev"; 

  // Hàm lấy token từ bộ nhớ
  Future<String?> _getToken(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Hàm lưu token mới vào bộ nhớ
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  // Hàm xóa token (Đăng xuất)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    // Tại đây bạn có thể điều hướng về màn hình Login
    print("Session expired. Logged out.");
  }

  // --- LOGIC REFRESH TOKEN ---
  Future<bool> _refreshToken() async {
    final refreshToken = await _getToken('refresh_token');
    
    if (refreshToken == null) return false;

    final url = Uri.parse('$baseUrl/auth/refresh'); // API refresh của Server bạn
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // Thường refresh token sẽ gửi trong Body hoặc Header Authorization
          // Tùy vào Server của bạn cấu hình. Ví dụ gửi trong body:
        },
        body: jsonEncode({'refresh_token': refreshToken}), 
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Server trả về cặp token mới
        await _saveTokens(data['access_token'], data['refresh_token']);
        print("Refresh token thành công!");
        return true;
      } else {
        // Refresh token cũng hết hạn hoặc không hợp lệ -> Logout
        await logout();
        return false;
      }
    } catch (e) {
      print("Lỗi khi refresh token: $e");
      return false;
    }
  }

  // --- HÀM GỌI API CHUNG (GET, POST...) ---
  
  // Ví dụ hàm GET có cơ chế tự refresh
  Future<http.Response> get(String endpoint) async {
    String? token = await _getToken('access_token');
    final url = Uri.parse('$baseUrl$endpoint');

    // 1. Gọi API lần đầu
    var response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // 2. Nếu lỗi 401 (Unauthorized) -> Token hết hạn
    if (response.statusCode == 401) {
      print("Token hết hạn (401). Đang thử refresh...");
      
      // 3. Thử lấy token mới
      bool success = await _refreshToken();

      if (success) {
        // 4. Lấy lại token mới từ storage
        token = await _getToken('access_token');
        
        // 5. Gọi lại API lần 2 với token mới
        response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    }

    return response;
  }

  // Tương tự cho hàm POST
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    String? token = await _getToken('access_token');
    final url = Uri.parse('$baseUrl$endpoint');

    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      print("Token hết hạn (401). Đang thử refresh...");
      bool success = await _refreshToken();
      if (success) {
        token = await _getToken('access_token');
        response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        );
      }
    }
    return response;
  }
}