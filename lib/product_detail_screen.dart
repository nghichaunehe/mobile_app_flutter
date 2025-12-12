import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';
import 'services/cart_service.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // Biến lưu lựa chọn tạm thời
  String? _selectedSize;
  String? _selectedColor;
  final CartService _cartService = CartService();
  bool _isAdding = false;
  @override
  Widget build(BuildContext context) {
    // 1. LẤY DỮ LIỆU ĐƯỢC TRUYỀN TỪ HOME SANG
    final product = ModalRoute.of(context)!.settings.arguments as Product;
    
    // Format tiền tệ
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');
    final formattedPrice = "${currencyFormatter.format(product.price)}₫";

    return Scaffold(
      body: Stack(
        children: [
          // Phần nội dung cuộn được
          CustomScrollView(
            slivers: [
              // 2. Ảnh sản phẩm (SliverAppBar)
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                backgroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: product.imageBase64.startsWith('http')
                      ? Image.network(
                          product.imageBase64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
                        )
                      : Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 50)),
                ),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                   Container(
                    margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: IconButton(
                      icon: Icon(
                        product.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: product.isFavorite ? Colors.red : Colors.black
                      ),
                      onPressed: () {}, // Xử lý logic yêu thích sau
                    ),
                  ),
                ],
              ),

              // 3. Thông tin chi tiết
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên và Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 20),
                                  Text(" ${product.rating}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Text("(${product.reviewCount} đánh giá)", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      // Giá tiền
                      Text(
                        formattedPrice,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                      ),

                      const SizedBox(height: 24),
                      const Divider(),

                      // 4. Chọn Size (Dynamic từ List API)
                      const Text("Kích thước", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: product.sizes.map((size) {
                          final isSelected = _selectedSize == size;
                          return ChoiceChip(
                            label: Text(size),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedSize = selected ? size : null);
                            },
                            selectedColor: Theme.of(context).primaryColor,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // 5. Chọn Màu (Dynamic từ List API)
                      const Text("Màu sắc", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: product.colors.map((colorName) {
                          final isSelected = _selectedColor == colorName;
                          return ChoiceChip(
                            label: Text(colorName),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedColor = selected ? colorName : null);
                            },
                            selectedColor: Theme.of(context).primaryColor.withOpacity(0.8),
                            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // 6. Mô tả sản phẩm
                      const Text("Mô tả sản phẩm", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: const TextStyle(color: Colors.black87, height: 1.5),
                      ),
                      
                      // Khoảng trống để không bị nút đè lên nội dung
                      const SizedBox(height: 100), 
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 7. Bottom Bar (Nút thêm vào giỏ)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined),
                        onPressed: () {Navigator.pushNamed(context, '/cart');},
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isAdding ? null : () async { // Disable nút khi đang loading
                          if (_selectedSize == null || _selectedColor == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Vui lòng chọn Size và Màu sắc")),
                            );
                            return;
                          }

                          setState(() => _isAdding = true); // Bật loading

                          // Gọi API
                          bool success = await _cartService.addToCart(
                            productId: product.id, // Đảm bảo class Product truyền sang có field id
                            quantity: 1,
                            size: _selectedSize!,
                            color: _selectedColor!,
                          );

                          setState(() => _isAdding = false); // Tắt loading

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Đã thêm vào giỏ hàng!"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Lỗi khi thêm vào giỏ hàng"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isAdding 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Thêm vào giỏ hàng", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}