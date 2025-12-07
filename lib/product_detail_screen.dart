import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy màu từ Theme
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundLight = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 450.0, // Chiều cao ảnh lớn
                pinned: true,
                // SỬA: Dùng backgroundLight (non-nullable assertion) cho AppBar khi thu nhỏ
                backgroundColor: backgroundLight!, 
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: const Text("Chi tiết sản phẩm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  background: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuDSmzo-mbo8Re93z8Qcjl6GinwygoC4rDMj7luTwmpDoN-cLLVbQCjpjCEoT8Y-nSpgZoqUznBWfzajN810btG9u0jpCdaNW7gWqAyVfwXs6518JCLt9FixFKnQQyuRgG2w-t8kALyNGhjfF_JT_2iuIyh4IS6nvMUO4PJwJL9aG4FTepcB842rflyGDVgZA0yz1wAicMsDm-LiQoR_cFnl4JOdEFPt4xtHNGRBsvfC_lZahGhlkWlc7fvNlLFeh9EY3ERvacm1Og"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.favorite_border, color: Colors.white), onPressed: () {}),
                ],
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _buildProductInfo(context, primaryColor),
                    _buildOptions(context, primaryColor),
                    _buildDescription(primaryColor),
                    const SizedBox(height: 100), // Padding cho Footer CTA
                  ],
                ),
              ),
            ],
          ),
          // CTA Footer cố định
          _buildDetailFooter(context, primaryColor, backgroundLight),
        ],
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Áo Hoodie Thể Thao", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          Row(
            children: [
              // Đánh giá sao (Dùng Fill 1 cho sao liền và Half cho sao rỗng)
              Row(children: List.generate(4, (index) => Icon(Icons.star, size: 16, color: primaryColor))),
              Icon(Icons.star_half, size: 16, color: primaryColor),
              const SizedBox(width: 8),
              const Text("4.5 (320 đánh giá)", style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text("750.000₫", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(BuildContext context, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color Selector
          const Text("Màu sắc", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              // Màu Blue (Đã chọn)
              _colorSwatch(Colors.blue, primaryColor: primaryColor), 
              _colorSwatch(Colors.black),
              _colorSwatch(Colors.grey),
              _colorSwatch(Colors.white),
            ],
          ),
          const SizedBox(height: 24),

          // Size Selector
          const Text("Kích thước", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _sizeButton("S", false),
              // Size M (Đã chọn)
              _sizeButton("M", true, primaryColor: primaryColor), 
              _sizeButton("L", false),
              _sizeButton("XL", false),
            ],
          ),
        ],
      ),
    );
  }

  // Helper cho việc tạo vòng tròn màu
  Widget _colorSwatch(Color color, {Color? primaryColor}) {
    final isSelected = primaryColor != null;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? primaryColor! : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        // Tạo hiệu ứng "ring" bằng BoxShadow (giống Tailwind)
        boxShadow: isSelected 
            ? [BoxShadow(color: primaryColor!.withOpacity(0.3), blurRadius: 4, spreadRadius: 2)] 
            : null,
      ),
    );
  }

  // Helper cho việc tạo nút Size
  Widget _sizeButton(String size, bool isSelected, {Color? primaryColor}) {
    final color = isSelected ? primaryColor! : Colors.grey[300];
    final textColor = isSelected ? primaryColor! : Colors.grey[800];
    
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color!, width: isSelected ? 2 : 1),
        color: isSelected ? primaryColor!.withOpacity(0.2) : Colors.white,
      ),
      child: Text(size, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
    );
  }

  Widget _buildDescription(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Mô tả sản phẩm", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
            "Chất liệu vải cao cấp, co giãn và thoáng khí, mang lại cảm giác thoải mái tối đa khi vận động. Thiết kế tối giản, hiện đại, phù hợp cho cả nam và nữ.",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text("Xem thêm", style: TextStyle(fontWeight: FontWeight.w600, color: primaryColor)),
        ],
      ),
    );
  }

  // Helper cho Footer CTA cố định
  Widget _buildDetailFooter(BuildContext context, Color primaryColor, Color backgroundLight) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Dùng backdrop-blur giả lập bằng cách làm màu nền mờ
          color: backgroundLight.withOpacity(0.9), 
          border: const Border(top: BorderSide(color: Colors.grey, width: 0.2)),
        ),
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.shopping_bag),
          label: const Text("Thêm vào giỏ hàng"),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            // Thêm shadow (giống shadow-lg shadow-primary/30)
            elevation: 8, 
            shadowColor: primaryColor.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}