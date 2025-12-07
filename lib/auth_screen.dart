// --- AUTH SCREEN (Đăng nhập/Đăng ký) ---
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Key để quản lý Form và Validation
  final _formKey = GlobalKey<FormState>();

  // Biến trạng thái: true = Đăng nhập, false = Đăng ký
  bool isLogin = true;
  // Biến trạng thái: Ẩn/Hiện mật khẩu
  bool obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Hàm xử lý logic đăng nhập/đăng ký
  void _handleAuth() {
    // 1. Ẩn bàn phím trước khi xử lý
    FocusScope.of(context).unfocus();

    // 2. Kiểm tra dữ liệu nhập vào (Validate)
    if (_formKey.currentState!.validate()) {
      print("Email: ${_emailController.text}");
      print("Password: ${_passwordController.text}");
      print("Mode: ${isLogin ? 'Đăng nhập' : 'Đăng ký'}");

      // Hiện thông báo giả lập thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đang xử lý ${isLogin ? 'đăng nhập' : 'đăng ký'}..."),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
      // TODO: Xử lý gọi API
    }
  }
  
  // Màu chủ đạo được lấy từ Theme
  Color get primaryColor => Theme.of(context).primaryColor;

  @override
  Widget build(BuildContext context) {
    // GestureDetector bọc ngoài cùng để ẩn bàn phím khi bấm ra ngoài
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Header (Back Button & Title) ---
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 24),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: Text(
                        isLogin ? "Đăng nhập" : "Đăng ký tài khoản",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Dummy để cân giữa title
                  ],
                ),
                
                const SizedBox(height: 32),

                // --- Logo Section (Dùng Icons.style theo mockup HTML) ---
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.2), // bg-primary/20
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.style, color: primaryColor, size: 40),
                  ),
                ),

                const SizedBox(height: 32),

                // --- Segmented Buttons (Toggle Login/Register) ---
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

                // --- Form Fields (Dùng Form và TextFormField cho validation) ---
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email Input
                      _buildLabel("Email hoặc số điện thoại"),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration("Nhập email hoặc sđt", Icons.person_outline),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập thông tin';
                          }
                          // Thêm logic validation phức tạp hơn nếu cần
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password Input
                      _buildLabel("Mật khẩu"),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: obscurePassword,
                        decoration: _inputDecoration("Nhập mật khẩu", Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          if (value.length < 6) {
                            return 'Mật khẩu phải có ít nhất 6 ký tự';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                // Forgot Password Link
                if (isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        "Quên mật khẩu?",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),

                // --- CTA Button ---
                ElevatedButton(
                  onPressed: _handleAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    fixedSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: primaryColor.withOpacity(0.3),
                  ),
                  child: Text(
                    isLogin ? "Đăng nhập" : "Đăng ký",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // --- Social Login Divider ---
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Hoặc tiếp tục với",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 24),

                // --- Social Buttons (Sử dụng Icon giả lập theo mockup) ---
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
                    Text(
                      isLogin ? "Chưa có tài khoản? " : "Đã có tài khoản? ",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
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
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
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

  // Widget con: Nút Toggle (Login/Register)
  Widget _buildToggleBtn(String title, bool isBtnLogin) {
    bool isSelected = isLogin == isBtnLogin;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isLogin = isBtnLogin;
            _formKey.currentState?.reset(); // Xóa lỗi cũ khi chuyển tab
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : [],
          ),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? primaryColor : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  // Widget con: Nút Mạng xã hội
  Widget _buildSocialBtn(IconData icon, Color color) {
    return Container(
      width: 60,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }

  // Widget con: Label cho Input
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.grey[800],
      ),
    );
  }

  // Style chung cho TextFormField
  InputDecoration _inputDecoration(String hint, IconData prefixIcon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: Icon(prefixIcon, color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}