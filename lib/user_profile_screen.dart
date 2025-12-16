import 'package:flutter/material.dart';
import 'secure_storage_manager.dart';
import 'orders_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Cấu hình màu sắc và font chữ tương tự Tailwind config
        scaffoldBackgroundColor: const Color(0xFFF5F7F8), // bg-background-light
        primaryColor: const Color(0xFF0D7FF2), // primary
        fontFamily: 'Roboto', // Hoặc 'Plus Jakarta Sans' nếu bạn đã thêm font
        useMaterial3: true,
      ),
      home: const UserProfileScreen(),
    );
  }
}

Future<void> _handleLogout(BuildContext context) async {
  // Hiện hộp thoại xác nhận
  final bool shouldLogout = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Đăng xuất"),
      content: const Text("Bạn có chắc chắn muốn đăng xuất?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Hủy"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("Đồng ý", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  ) ?? false;

  if (shouldLogout) {
    // Xóa JWT khỏi bộ nhớ an toàn
    await SecureStorageManager.deleteJwt();

    // Chuyển về màn hình Login và xóa hết lịch sử cũ
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }
}

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Màu primary từ thiết kế (#0d7ff2)
    const Color primaryColor = Color(0xFF0D7FF2);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Hồ sơ người dùng",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- PHẦN THÔNG TIN USER ---
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: NetworkImage('https://lh3.googleusercontent.com/a/default-user=s96-c'), // Placeholder
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Tên và Email
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Lê An",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A), // slate-900
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "lean@email.com",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B), // slate-500
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Nút Chỉnh sửa
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor.withOpacity(0.1), // bg-primary/20
                    foregroundColor: primaryColor, // text-primary
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Chỉnh sửa",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // --- NHÓM MENU 1 (Đơn hàng, Địa chỉ...) ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.local_mall_outlined,
                      text: "Đơn hàng của tôi",
                      iconColor: primaryColor,
                      iconBgColor: primaryColor.withOpacity(0.1),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const OrdersScreen()),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.location_on_outlined,
                      text: "Địa chỉ đã lưu",
                      iconColor: primaryColor,
                      iconBgColor: primaryColor.withOpacity(0.1),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.payment_outlined,
                      text: "Phương thức thanh toán",
                      iconColor: primaryColor,
                      iconBgColor: primaryColor.withOpacity(0.1),
                      isLast: true, // Để bo góc dưới nếu cần thiết kế chi tiết
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- NHÓM MENU 2 (Cài đặt, Mật khẩu...) ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.settings_outlined,
                      text: "Cài đặt",
                      iconColor: Colors.black54,
                      iconBgColor: Colors.grey.shade200,
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.lock_outline,
                      text: "Thay đổi mật khẩu",
                      iconColor: primaryColor,
                      iconBgColor: primaryColor.withOpacity(0.1),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.logout,
                      text: "Đăng xuất",
                      textColor: Colors.red,
                      iconColor: Colors.black54,
                      iconBgColor: Colors.grey.shade200,
                      showChevron: false,
                      isLast: true,
                      onTap: () => _handleLogout(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Widget con để tạo dòng kẻ ngăn cách
  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: Color(0xFFE2E8F0));
  }

  // Widget tái sử dụng cho từng mục menu
  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required Color iconColor,
    required Color iconBgColor,
    Color textColor = const Color(0xFF1E293B),
    bool showChevron = true,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast 
            ? const BorderRadius.vertical(bottom: Radius.circular(12))
            : null, // Bo góc khi nhấn nếu là item cuối
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon Box
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              // Text Title
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              // Chevron Icon
              if (showChevron)
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF94A3B8), // slate-400
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}