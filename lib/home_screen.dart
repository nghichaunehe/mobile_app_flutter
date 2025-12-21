import 'dart:async'; // Thêm để dùng Timer cho debounce
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'category_screen.dart';
import 'favorite_page.dart';
import '../services/api_service.dart';
import '../auth_screen.dart';

// --- Giữ nguyên các Model Category và Product ở đầu file cũ ---
// (Copy lại Class Category và Class Product từ code cũ của bạn vào đây nếu tách file)

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Không tên',
    );
  }
}

class Product {
  final int id;
  final String name;
  final int price;
  final String imageUrl;
  final String description;
  final double rating;
  final int reviewCount;
  final List<String> sizes;
  final List<String> colors;
  final bool isFavorite;
  final int? quantity;
  final bool? isSoldOut;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.rating,
    required this.reviewCount,
    required this.sizes,
    required this.colors,
    this.isFavorite = false,
    this.quantity,
    this.isSoldOut,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Không tên',
      price: json['price'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? 'Chưa có mô tả',
      rating: (json['rating'] is int) ? (json['rating'] as int).toDouble() : (json['rating'] ?? 0.0),
      reviewCount: json['reviewCount'] ?? 0,
      sizes: json['sizes'] != null ? List<String>.from(json['sizes']) : [],
      colors: json['colors'] != null ? List<String>.from(json['colors']) : [],
      quantity: json['quantity'],
      isSoldOut: json['isSoldOut'],
    );
  }
}

// --- Class hỗ trợ khoảng giá ---
class PriceRange {
  final String label;
  final int? min;
  final int? max;

  PriceRange(this.label, {this.min, this.max});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  int _selectedIndex = 0;

  // Dữ liệu
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isLoadingCategories = true;

  // --- State quản lý bộ lọc hiện tại (để hiển thị Chip) ---
  String? _activeSearchName;
  int? _activeCategoryId;
  PriceRange? _activePriceRange;

  // Danh sách khoảng giá định sẵn
  final List<PriceRange> _priceRanges = [
    PriceRange('Tất cả mức giá'),
    PriceRange('Dưới 100.000₫', max: 100000),
    PriceRange('100.000₫ - 300.000₫', min: 100000, max: 300000),
    PriceRange('300.000₫ - 500.000₫', min: 300000, max: 500000),
    PriceRange('500.000₫ - 1.000.000₫', min: 500000, max: 1000000),
    PriceRange('Trên 1.000.000₫', min: 1000000),
  ];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchProducts();
  }

  // --- API Categories ---
  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final response = await _apiService.get('/categories');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _categories = data.map((json) => Category.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print("Lỗi categories: $e");
    } finally {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  // --- API Products (Hỗ trợ lọc) ---
  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);

    // Xây dựng Endpoint dựa trên bộ lọc hiện tại
    String endpoint = '/products/search';
    final queryParams = <String, String>{};

    if (_activeSearchName != null && _activeSearchName!.isNotEmpty) {
      queryParams['name'] = _activeSearchName!;
    }
    if (_activeCategoryId != null) {
      queryParams['categoryId'] = _activeCategoryId.toString();
    }
    if (_activePriceRange != null) {
      if (_activePriceRange!.min != null) queryParams['minPrice'] = _activePriceRange!.min.toString();
      if (_activePriceRange!.max != null) queryParams['maxPrice'] = _activePriceRange!.max.toString();
    }

    // Nếu không có filter nào thì lấy random hoặc mặc định
    if (queryParams.isEmpty) {
      endpoint = '/products/random';
    } else {
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      endpoint = '$endpoint?$queryString';
    }

    try {
      print("Calling API: $endpoint");
      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        List<dynamic> data = [];
        // Xử lý trường hợp API trả về object chứa products hoặc list trực tiếp
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded.containsKey('products')) {
          data = decoded['products'];
        }

        setState(() {
          _products = data.map((json) => Product.fromJson(json)).toList();
        });
      } else if (response.statusCode == 401) {
         if (mounted) {
            await _apiService.logout();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
         }
      }
    } catch (e) {
      print("Lỗi products: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi tải dữ liệu: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Logic hiển thị Modal tìm kiếm nâng cao ---
  void _showAdvancedSearch() {
    // Các biến tạm thời trong Modal
    final TextEditingController searchController = TextEditingController(text: _activeSearchName);
    int? tempCategoryId = _activeCategoryId;
    PriceRange? tempPriceRange = _activePriceRange ?? _priceRanges[0];
    
    // Biến cho Autocomplete
    List<Product> suggestions = [];
    bool isLoadingSuggestions = false;
    Timer? debounce;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Cho phép full chiều cao khi có bàn phím
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            // Hàm gọi API Autocomplete
            void onSearchChanged(String query) {
              if (debounce?.isActive ?? false) debounce!.cancel();
              
              if (query.trim().isEmpty) {
                setModalState(() => suggestions = []);
                return;
              }

              // Debounce 500ms: Đợi người dùng ngừng gõ mới gọi API
              debounce = Timer(const Duration(milliseconds: 500), () async {
                setModalState(() => isLoadingSuggestions = true);
                try {
                  // Gọi API search để lấy gợi ý (có thể dùng endpoint riêng nếu có)
                  final res = await _apiService.get('/products/search?name=${Uri.encodeComponent(query)}');
                  if (res.statusCode == 200) {
                    final List<dynamic> data = json.decode(res.body);
                    if (mounted) {
                      setModalState(() {
                        suggestions = data.map((e) => Product.fromJson(e)).take(5).toList(); // Chỉ lấy 5 gợi ý
                      });
                    }
                  }
                } catch (e) {
                  print("Lỗi autocomplete: $e");
                } finally {
                  if (mounted) setModalState(() => isLoadingSuggestions = false);
                }
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                top: 20, 
                left: 20, 
                right: 20, 
                bottom: MediaQuery.of(context).viewInsets.bottom + 20 // Đẩy lên khi có bàn phím
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Bộ lọc tìm kiếm", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 1. Ô nhập liệu (Có Autocomplete)
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Tên sản phẩm',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: isLoadingSuggestions 
                        ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)) 
                        : null,
                    ),
                    onChanged: onSearchChanged,
                  ),
                  
                  // Danh sách gợi ý (Dropdown List khi gõ)
                  if (suggestions.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          final p = suggestions[index];
                          return ListTile(
                            leading: Image.network(p.imageUrl, width: 30, height: 30, errorBuilder: (_,__,___) => const Icon(Icons.image)),
                            title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () {
                              // Khi chọn gợi ý: điền vào ô text và xóa gợi ý
                              searchController.text = p.name;
                              setModalState(() => suggestions = []);
                            },
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  // 2. Dropdown Danh mục
                  DropdownButtonFormField<int?>(
                    value: tempCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Danh mục',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("Tất cả danh mục")),
                      ..._categories.map((cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name),
                      ))
                    ],
                    onChanged: (val) => setModalState(() => tempCategoryId = val),
                  ),

                  const SizedBox(height: 16),

                  // 3. Dropdown Khoảng giá (Yêu cầu của bạn)
                  DropdownButtonFormField<PriceRange>(
                    value: tempPriceRange, // Cần override == và hashCode trong PriceRange nếu dùng object, hoặc dùng index
                    // Để đơn giản, ta so sánh label hoặc dùng index, ở đây ta dùng logic tìm kiếm trong list
                    items: _priceRanges.map((range) => DropdownMenuItem(
                      value: range,
                      child: Text(range.label),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => tempPriceRange = val);
                    },
                    decoration: InputDecoration(
                      labelText: 'Khoảng giá',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. Nút Tìm kiếm
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Đóng modal
                      // Cập nhật State chính và gọi API
                      setState(() {
                        _activeSearchName = searchController.text.trim();
                        _activeCategoryId = tempCategoryId;
                        _activePriceRange = tempPriceRange;
                        
                        // Nếu chọn "Tất cả mức giá" thì reset về null cho logic API dễ xử lý
                        if (_activePriceRange?.min == null && _activePriceRange?.max == null) {
                           _activePriceRange = null; 
                        }
                      });
                      _fetchProducts(); // Gọi lại API search
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Tìm kiếm", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      }
    );
  }

  // --- Widget hiển thị các Filter đang áp dụng (Dạng Chips/Buttons) ---
  Widget _buildActiveFilters() {
    List<Widget> chips = [];

    // Chip cho Tên
    if (_activeSearchName != null && _activeSearchName!.isNotEmpty) {
      chips.add(InputChip(
        label: Text('Tìm: $_activeSearchName'),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: () {
          setState(() => _activeSearchName = null);
          _fetchProducts();
        },
        backgroundColor: Colors.blue[50],
        labelStyle: TextStyle(color: Colors.blue[800]),
      ));
    }

    // Chip cho Danh mục
    if (_activeCategoryId != null) {
      final catName = _categories.firstWhere((c) => c.id == _activeCategoryId, orElse: () => Category(id: 0, name: 'Unknown')).name;
      chips.add(InputChip(
        label: Text(catName),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: () {
          setState(() => _activeCategoryId = null);
          _fetchProducts();
        },
        backgroundColor: Colors.green[50],
        labelStyle: TextStyle(color: Colors.green[800]),
      ));
    }

    // Chip cho Giá
    if (_activePriceRange != null) {
      chips.add(InputChip(
        label: Text(_activePriceRange!.label),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: () {
          setState(() => _activePriceRange = null);
          _fetchProducts();
        },
        backgroundColor: Colors.orange[50],
        labelStyle: TextStyle(color: Colors.orange[800]),
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: chips,
      ),
    );
  }

  // --- Phần UI chính ---
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      body: _buildBody(primaryColor),
      bottomNavigationBar: _buildBottomNavBar(primaryColor),
    );
  }

  Widget _buildBody(Color primaryColor) {
     switch (_selectedIndex) {
      case 0: return _buildHomeContent(primaryColor);
      case 1: return const CategoryPage();
      case 2: return const FavoritePage();
      default: return _buildHomeContent(primaryColor);
    }
  }

  Widget _buildHomeContent(Color primaryColor) {
    return RefreshIndicator(
      onRefresh: () async {
        // Reset hết filter khi kéo xuống refresh
        setState(() {
          _activeSearchName = null;
          _activeCategoryId = null;
          _activePriceRange = null;
        });
        await _fetchCategories();
        await _fetchProducts();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAppBar(context, primaryColor),
            
            // Thanh tìm kiếm mới (gọi BottomSheet)
            _buildSearchBar(context, primaryColor),
            
            // Khu vực hiển thị nút Filter (Yêu cầu: hiển thị dưới dạng btn)
            _buildActiveFilters(),

            _buildBanner(),
            const SizedBox(height: 16),
            _buildSectionHeader("Danh mục"),
            _buildCategoryChips(context, primaryColor),
            
            // Tiêu đề thay đổi tùy theo việc có đang lọc hay không
            _buildProductHeader(context, 
              (_activeSearchName != null || _activeCategoryId != null) 
              ? "Kết quả tìm kiếm" 
              : "Sản phẩm nổi bật"
            ),
            
            _buildProductGrid(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // --- Search Bar Widget (Updated onTap) ---
  Widget _buildSearchBar(BuildContext context, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GestureDetector(
        onTap: _showAdvancedSearch, // Mở Modal tìm kiếm mới
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey[600], size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _activeSearchName ?? 'Tìm kiếm sản phẩm...',
                  style: TextStyle(color: Colors.grey[_activeSearchName != null ? 900 : 600], fontSize: 15),
                ),
              ),
              Icon(Icons.tune, color: primaryColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // --- Category Chips (Chỉnh sửa để update filter state) ---
  Widget _buildCategoryChips(BuildContext context, Color primaryColor) {
    if (_isLoadingCategories) return const Center(child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator()));

    final allCategories = [
      {'id': null, 'name': 'Tất cả', 'icon': Icons.apps},
      ..._categories.map((cat) => {'id': cat.id, 'name': cat.name, 'icon': Icons.style_outlined}),
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allCategories.length,
        itemBuilder: (context, index) {
          final category = allCategories[index];
          final cId = category['id'] as int?;
          // Logic active dựa trên _activeCategoryId
          final isSelected = _activeCategoryId == cId;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeCategoryId = cId;
              });
              _fetchProducts();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? Colors.transparent : Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(category['icon'] as IconData, size: 18, color: isSelected ? Colors.white : Colors.grey[800]),
                  const SizedBox(width: 8),
                  Text(category['name'] as String, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[800], fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Widget Grid Sản phẩm (Copy logic cũ) ---
  Widget _buildProductGrid(BuildContext context) {
    if (_isLoading) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
    if (_products.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("Không tìm thấy sản phẩm nào")));

    final currencyFormatter = NumberFormat('#,###', 'vi_VN');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.7,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
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
                          borderRadius: BorderRadius.circular(12), color: Colors.white,
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(product.imageUrl, fit: BoxFit.cover, width: double.infinity,
                            errorBuilder: (ctx, err, stack) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                          ),
                        ),
                      ),
                      // Badge hiển thị trạng thái hàng
                      if (product.isSoldOut == true)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'HẾT HÀNG',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else if (product.quantity != null && product.quantity! > 0 && product.quantity! <= 10)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Còn ${product.quantity}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(padding: const EdgeInsets.only(top: 8), child: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                Text("${currencyFormatter.format(product.price)}₫", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Bottom Nav Bar & Header Helpers (Giữ nguyên hoặc dùng lại hàm cũ) ---
  Widget _buildBottomNavBar(Color primaryColor) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.home, "Trang chủ", primaryColor),
          
          _navItem(2, Icons.favorite_border, "Yêu thích", primaryColor),
          _navItem(3, Icons.person_outline, "Tài khoản", primaryColor),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, Color primaryColor) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        if (index == 3) Navigator.of(context).pushNamed('/profile');
        else setState(() => _selectedIndex = index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? primaryColor : Colors.grey, size: 24),
          Text(label, style: TextStyle(color: isSelected ? primaryColor : Colors.grey, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

// --- Các Widget tĩnh (AppBar, Banner, Header) giữ nguyên như cũ ---
Widget _buildAppBar(BuildContext context, Color primaryColor) {
  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48),
          const Text("Trang chủ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.shopping_cart), onPressed: () => Navigator.pushNamed(context, '/cart')),
        ],
      ),
    ),
  );
}

Widget _buildBanner() {
  return Container(
    height: 180, margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      image: const DecorationImage(image: NetworkImage("https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=800&q=80"), fit: BoxFit.cover),
    ),
  );
}

Widget _buildSectionHeader(String title) {
  return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)));
}

Widget _buildProductHeader(BuildContext context, String title) {
  return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)));
}