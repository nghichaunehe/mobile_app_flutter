import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Index 3 tương ứng với mục "Tài khoản"
    if (index == 3) { 
      // Chuyển hướng đến màn hình Profile
      Navigator.of(context).pushNamed('/profile');
    } 
    // Nếu index là 0, 1, 2 thì bạn sẽ xử lý chuyển đổi nội dung Body tại đây
  }

  @override
  Widget build(BuildContext context) {
    // Lấy màu chủ đạo từ Theme
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top App Bar (Search & Cart)
            _buildAppBar(context, primaryColor),
            
            // Promotional Banner
            _buildBanner(),
            
            const SizedBox(height: 10),
            
            // Dot Indicators (Dùng primaryColor)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle)),
                Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: primaryColor.withOpacity(0.3), shape: BoxShape.circle)),
                Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: primaryColor.withOpacity(0.3), shape: BoxShape.circle)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Categories
            _buildSectionHeader("Danh mục"),
            _buildCategoryChips(context, primaryColor), // Truyền primaryColor
            
            // Featured Products
            _buildProductHeader(context, "Sản phẩm nổi bật"),
            _buildProductGrid(context),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavBar(primaryColor),
    );
  }
}

// --- Helper Widgets ---

Widget _buildAppBar(BuildContext context, Color primaryColor) {
  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.search, size: 24, color: Colors.grey),
          ),
          const Text(
            "Trang chủ",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart, size: 24),
                  onPressed: () => Navigator.pushNamed(context, '/cart'),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: primaryColor, // Dùng primaryColor
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 10)),
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
        image: const DecorationImage(
          image: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuD66EjKzbji1DUKmmKw3enFA0jjQCty6-CANeEsLQAWsoMlPIFdT-RCopp-2F6LSWT_4NzaVGb_dSDxu7fsJizYoDB4sSidZjzApO-uLUVlYw2Osp4nEjjurEst35YqOmxS4PtXHGhbP1K10ct4Ddap2LeTEncW19a8Br4qNGVpRNgPEUGgOBW7FWSstIeGToRoOI7XRhuTZl3qoltEHAAUg-wfgF_XI0klV1C8T4d9TkTyAcY2HR0xqxf1uWpvLWK6rGKAAoTtkw"), 
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
    // SỬA: Dùng Icon chuẩn, phù hợp với ý nghĩa (Style cho Áo Thun)
    {'name': 'Áo Thun', 'icon': Icons.style_outlined},
    
    // SỬA: Dùng Icon chuẩn (Male cho Quần Jean)
    {'name': 'Quần Jean', 'icon': Icons.male_outlined},
    
    // SỬA: Dùng Icon chuẩn (Female cho Váy)
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
        
        // Truy cập màu qua biến local primaryColor
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
            // Box shadow chỉ áp dụng cho chip không phải primary
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

Widget _buildProductGrid(BuildContext context) {
  final products = [
    {'name': 'Áo Thun In Họa Tiết', 'price': '250.000₫', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAOiAUsS09QaG4dmzEq36NzlsyFX6I6GuZ3RyyuvcFuVAHiGrz3Kogr3Y1Z5Y3KBvuhNqDunoJKBn3q3hKvGUI73GEcs2HYHzeooGkUcmGlz2UwPIy3r3JC7zwF5FdkM5c8DCx8xTNkz9RUz1bLIayfC1NcPnm86SNDmpunxM6GP3DaD1OLD3M_EumUIKV-ohPq1syztKX2YP_dLSIUhT5BluHtcbv8-znHrDbWLPEj0giL8CtFmTRLBBjzyhoY11B6WzG-C1DHmA', 'isFavorite': false},
    {'name': 'Quần Jean Dáng Rộng', 'price': '450.000₫', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAf9wvgnkJ7-oNsoKh8qa6Uv7jOQfUwWu1TgqYzTalR1BvMQVygRV6mc5MrXW3ELa8avy8KwRF3wIawAZ0-Cgl7fWQzexZffexkdJSnxx8hyWZwJb6MpbwLf9xvl3Ywo7RnEzmJ1gYMaZES4GgN1qel8VykpVIee-QlfmheUdANPVAej7A8qQD0epB6d9J8uv-VNdN0ug0M58pc6fh5uANx3Me5AO65AcT-hm_oCDapGR0CkblSNKgZUqK8ZiAITTWJmpojWYjQrw', 'isFavorite': false},
    {'name': 'Váy Hoa Mùa Hè', 'price': '380.000₫', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBzOjhsl6W2mg3QFDvYO3pHFOlUjtQ4JAEfuAg7SONPcgJeFjj0LJ-QVtu1QvMFcjEbHDWLAvkiHWbKDtglzas7-Y8VmBemSVPoYE0mNg5cvr2bK47mf3R-4HMwalWmz0b4NDIlO7ilD7s-k3cAeZngxHkDlKZkUtv10PiRlHucIIH30ZH89Mn-wwmo6qxJFpI5qcknKhwJkCmf0d9FNPg34FH8EWjvmR9y19bbS0cqWtvs2qQAKFL4lzNovL3sPL6JO3fn1rONDA', 'isFavorite': true},
    {'name': 'Áo Khoác Dáng Dài', 'price': '790.000₫', 'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBD_mujTd9gNNwxWD0ZkD0cOUVVA_MTOZHdxW2uvXpCXp0ZAeiiuLklm_1rcpZ11Bc0n7bawkk1tvApXcudUWR5PcyprERWLu2JJ3FJjzGj1KKpebGsw6YJygAFDNXXHCE7NCcDV-lFYcq0dGfYYe1DbQc07MqA305FXRtOrfw48SuPRoyG5inqcdy_qWz9DnLIcSMjklkaxDgr6vQ1TJHQMv6zkqQbWE1Nn7MVy9B6iCFOOy42uNESqRAgmOAnlnG_M1JZB0tuIA', 'isFavorite': false},
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7, 
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/detail'),
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
                        image: DecorationImage(
                          image: NetworkImage(product['image'] as String),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Icon(
                          product['isFavorite'] == true ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: product['isFavorite'] == true ? Colors.red : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4.0, top: 8.0),
                child: Text(product['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4.0, top: 4.0),
                child: Text(product['price'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildBottomNavBar(Color primaryColor) {
  // Lấy màu nền Scaffolds để có hiệu ứng backdrop-blur trong HTML
  final backgroundLight = const Color(0xFFF5F7F8); 
  
  return Container(
    height: 64,
    decoration: BoxDecoration(
      color: backgroundLight.withOpacity(0.8),
      border: const Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1.0)), // Thay border màu xám
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _navItem(Icons.home, "Trang chủ", true, primaryColor),
        _navItem(Icons.category_outlined, "Danh mục", false, primaryColor),
        _navItem(Icons.favorite_border, "Yêu thích", false, primaryColor),
        _navItem(Icons.person_outline, "Tài khoản", false, primaryColor),
      ],
    ),
  );
}

Widget _navItem(IconData icon, String label, bool isSelected, Color primaryColor) {
  final color = isSelected ? primaryColor : Colors.grey[500];
  final fontWeight = isSelected ? FontWeight.bold : FontWeight.w500;

  return InkWell(
    onTap: () {}, 
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: fontWeight)),
      ],
    ),
  );
}