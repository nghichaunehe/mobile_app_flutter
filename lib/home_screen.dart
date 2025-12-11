import 'dart:convert'; // Để xử lý JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Thư viện gọi API
import 'package:intl/intl.dart'; // Thư viện format tiền tệ

import 'category_screen.dart';
import 'favorite_page.dart';

// --- 1. Tạo Model để hứng dữ liệu từ API ---
class Product {
final int id;
  final String name;
  final int price;
  final String imageBase64; // Thực chất là URL ảnh
  final String description; // Thêm mô tả
  final double rating;
  final int reviewCount;    // Thêm số lượng review
  final List<String> sizes; // Thêm Size
  final List<String> colors;// Thêm Color
  final bool isFavorite;

  Product({
required this.id,
    required this.name,
    required this.price,
    required this.imageBase64,
    required this.description,
    required this.rating,
    required this.reviewCount,
    required this.sizes,
    required this.colors,
    this.isFavorite = false,
  });

factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Không tên',
      price: json['price'] ?? 0,
      imageBase64: json['imageBase64'] ?? '',
      description: json['description'] ?? 'Chưa có mô tả',
      rating: (json['rating'] is int) ? (json['rating'] as int).toDouble() : (json['rating'] ?? 0.0),
      reviewCount: json['reviewCount'] ?? 0,
      // Xử lý mảng JSON an toàn
      sizes: json['sizes'] != null ? List<String>.from(json['sizes']) : [],
      colors: json['colors'] != null ? List<String>.from(json['colors']) : [],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  // Biến trạng thái cho việc tải dữ liệu
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts(); // Gọi API ngay khi màn hình mở
  }

  // --- Hàm gọi API ---
  Future<void> _fetchProducts() async {
    try {
      // Lưu ý: Nếu chạy trên máy ảo Android, localhost là 10.0.2.2
      // Nếu chạy Web hoặc iOS Simulator thì dùng localhost vẫn được
      final url = Uri.parse('http://localhost:3001/products/random'); 
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _products = data.map((json) => Product.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print("Lỗi gọi API: $e");
      setState(() {
        _isLoading = false;
      });
      // Có thể hiển thị thông báo lỗi cho user tại đây
    }
  }

  // Hàm xử lý Bottom Nav
  void _onItemTapped(int index) {
    if (index == 3) {
      Navigator.of(context).pushNamed('/profile');
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const CategoryPage();
      case 2:
        return const FavoritePage();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    final primaryColor = Theme.of(context).primaryColor;
    return RefreshIndicator( // Cho phép kéo xuống để reload
      onRefresh: _fetchProducts,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAppBar(context, primaryColor),
            _buildBanner(),
            const SizedBox(height: 10),
            // Indicator dots (tĩnh)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle)),
                Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: primaryColor.withOpacity(0.3), shape: BoxShape.circle)),
                Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: primaryColor.withOpacity(0.3), shape: BoxShape.circle)),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionHeader("Danh mục"),
            _buildCategoryChips(context, primaryColor),
            _buildProductHeader(context, "Sản phẩm nổi bật"),
            
            // Grid sản phẩm (Dynamic)
            _buildProductGrid(context),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // --- Widget Grid Sản Phẩm (Đã cập nhật để dùng dữ liệu API) ---
  Widget _buildProductGrid(BuildContext context) {
    // 1. Nếu đang tải thì quay vòng tròn
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Nếu không có dữ liệu
    if (_products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text("Không kết nối được server hoặc không có sản phẩm")),
      );
    }

    // 3. Hiển thị lưới dữ liệu
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // Để SingleChildScrollView cuộn được
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          
          // Format giá tiền: 250 -> 250.000₫
          final currencyFormatter = NumberFormat('#,###', 'vi_VN');
          // Giả sử API trả về 250 tức là 250.000 VND
          final formattedPrice = "${currencyFormatter.format(product.price * 1000)}₫";

          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/detail', arguments: product),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        // Xử lý hình ảnh (Network hoặc Placeholder)
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: product.imageBase64.startsWith('http') 
                            ? Image.network(
                                product.imageBase64,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error)),
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Center(child: Icon(Icons.image_not_supported)),
                              ),
                        ),
                      ),
                      // Nút yêu thích
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          height: 32, width: 32,
                          decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Icon(
                            product.isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: product.isFavorite ? Colors.red : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, top: 8.0),
                  child: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, top: 4.0),
                  child: Text(
                    formattedPrice,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                // Hiển thị Rating từ API
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, top: 2.0),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      Text(" ${product.rating}", style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavBar(Color primaryColor) {
    final backgroundLight = const Color(0xFFF5F7F8);
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: backgroundLight.withOpacity(0.95),
        border: const Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.home, "Trang chủ", primaryColor),
          _navItem(1, Icons.category_outlined, "Danh mục", primaryColor),
          _navItem(2, Icons.favorite_border, "Yêu thích", primaryColor),
          _navItem(3, Icons.person_outline, "Tài khoản", primaryColor),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, Color primaryColor) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? primaryColor : Colors.grey[500];
    final fontWeight = isSelected ? FontWeight.bold : FontWeight.w500;
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: fontWeight)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(primaryColor),
    );
  }
}

// --- Helper Widgets (Giữ nguyên phần UI tĩnh) ---

Widget _buildAppBar(BuildContext context, Color primaryColor) {
  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(
            width: 48, height: 48,
            child: Icon(Icons.search, size: 24, color: Colors.grey),
          ),
          const Text(
            "Trang chủ",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: 48, height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart, size: 24),
                  onPressed: () {
                    Navigator.pushNamed(context, '/cart');
                  },
                ),
                Positioned(
                  top: 4, right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildBanner() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[300],
        image: const DecorationImage(
          image: NetworkImage("https://images.unsplash.com/photo-1483985988355-763728e1935b?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text("Bộ sưu tập Hè 2024", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          Text("Giảm giá tới 30%", style: TextStyle(fontSize: 14, color: Colors.white70)),
        ],
      ),
    ),
  );
}

Widget _buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
    child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
  );
}

Widget _buildProductHeader(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: () {},
          child: Text("Xem tất cả", style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14)),
        ),
      ],
    ),
  );
}

Widget _buildCategoryChips(BuildContext context, Color primaryColor) {
  final categories = [
    {'name': 'Áo Thun', 'icon': Icons.style_outlined},
    {'name': 'Quần Jean', 'icon': Icons.male_outlined},
    {'name': 'Váy', 'icon': Icons.female_outlined},
    {'name': 'Áo Khoác', 'icon': Icons.checkroom_outlined},
    {'name': 'Giảm giá', 'icon': Icons.sell, 'isPrimary': true},
  ];

  return SizedBox(
    height: 40,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isPrimary = category['isPrimary'] == true;
        final color = isPrimary ? primaryColor : Colors.grey[800];
        final bgColor = isPrimary ? primaryColor.withOpacity(0.2) : Colors.white;
        final borderColor = isPrimary ? Colors.transparent : Colors.grey[300];

        return Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor!),
            boxShadow: isPrimary ? null : [const BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Row(
            children: [
              Icon(category['icon'] as IconData, size: 20, color: color),
              const SizedBox(width: 8),
              Text(category['name'] as String, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        );
      },
    ),
  );
}