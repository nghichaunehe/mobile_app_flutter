import 'package:flutter/material.dart';
import 'dart:convert'; // Để dùng jsonEncode, jsonDecode
import 'package:http/http.dart' as http; // Để gọi API
import 'home_screen.dart'; // import Home Page
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  bool isLogin = true;
  bool obscurePassword = true;
  bool _isLoading = false; // Biến trạng thái loading khi gọi API

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();


  final String _baseUrl = "http://localhost:3001"; 

  Future<void> _handleAuth() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final endpoint = isLogin ? '/auth/login' : '/auth/register';

    final url = Uri.parse('$_baseUrl$endpoint');

    final Map<String, String> body = {
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        
        final prefs = await SharedPreferences.getInstance();
        
        String? token = responseData['access_token']; 
        String? refreshToken = responseData['refresh_token'];

        if (token != null) {
          await prefs.setString('access_token', token);
          print("Đã lưu Token: $token");
        }
        
        if (responseData['userId'] != null) {
           await prefs.setString('userId', responseData['userId'].toString());
        }

        if (responseData['userId'] != null) {
          await prefs.setString('userId', responseData['userId'].toString());
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isLogin ? "Đăng nhập thành công!" : "Đăng ký thành công!"),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? "Có lỗi xảy ra"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // ... Xử lý lỗi kết nối như cũ
      print("Lỗi: $e");
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi kết nối Server"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color get primaryColor => Theme.of(context).primaryColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Header ---
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 24),
                        onPressed: () {
                          if (Navigator.canPop(context)) Navigator.pop(context);
                        },
                      ),
                    ),
                    Expanded(
                      child: Text(
                        isLogin ? "Đăng nhập" : "Đăng ký tài khoản",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[900]),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                
                const SizedBox(height: 32),

                // --- Logo ---
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.style, color: primaryColor, size: 40),
                  ),
                ),

                const SizedBox(height: 32),

                // --- Toggle Buttons ---
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildToggleBtn("Đăng nhập", true),
                      _buildToggleBtn("Đăng ký", false),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- Form ---
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Email hoặc số điện thoại"),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration("Nhập email hoặc sđt", Icons.person_outline),
                        validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập thông tin' : null,
                      ),

                      const SizedBox(height: 16),

                      _buildLabel("Mật khẩu"),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: obscurePassword,
                        decoration: _inputDecoration("Nhập mật khẩu", Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
                            onPressed: () => setState(() => obscurePassword = !obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
                          if (value.length < 6) return 'Mật khẩu quá ngắn';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                if (isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text("Quên mật khẩu?", style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                    ),
                  ),
                
                const SizedBox(height: 16),

                // --- CTA Button (Updated with Loading) ---
                ElevatedButton(
                  // Nếu đang loading thì disable nút (onPressed = null)
                  onPressed: _isLoading ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    fixedSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 24, 
                        width: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : Text(
                        isLogin ? "Đăng nhập" : "Đăng ký",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                ),

                const SizedBox(height: 32),

                // --- Social Divider & Buttons (Giữ nguyên) ---
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text("Hoặc tiếp tục với", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialBtn(Icons.g_mobiledata, Colors.red),
                    const SizedBox(width: 16),
                    _buildSocialBtn(Icons.facebook, Colors.blue),
                    const SizedBox(width: 16),
                    _buildSocialBtn(Icons.apple, Colors.black),
                  ],
                ),
                const SizedBox(height: 32),

                // --- Footer Link ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(isLogin ? "Chưa có tài khoản? " : "Đã có tài khoản? ", style: TextStyle(color: Colors.grey[600])),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isLogin = !isLogin;
                          _formKey.currentState?.reset();
                          _emailController.clear();
                          _passwordController.clear();
                        });
                      },
                      child: Text(
                        isLogin ? "Đăng ký ngay" : "Đăng nhập ngay",
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Các Widget phụ trợ (Giữ nguyên) ---
  Widget _buildToggleBtn(String title, bool isBtnLogin) {
    bool isSelected = isLogin == isBtnLogin;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          isLogin = isBtnLogin;
          _formKey.currentState?.reset();
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? primaryColor : Colors.grey[600])),
        ),
      ),
    );
  }

  Widget _buildSocialBtn(IconData icon, Color color) {
    return Container(
      width: 60, height: 56,
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 30),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[800]));
  }

  InputDecoration _inputDecoration(String hint, IconData prefixIcon) {
    return InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: Icon(prefixIcon, color: Colors.grey[400]),
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
    );
  }
}