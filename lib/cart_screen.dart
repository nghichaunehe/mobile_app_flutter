import 'package:flutter/material.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy màu từ Theme
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundLight = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      // Top App Bar
      appBar: AppBar(
        title: const Text("Giỏ hàng", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        // Áp dụng background mờ cho AppBar (giả lập backdrop-blur)
        backgroundColor: backgroundLight.withOpacity(0.8),
        elevation: 0.5, // Dùng elevation để giả lập border-b
      ),
      
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // List Item 1
                _buildCartItem(context, 'Áo Thun Trơn', 'Size: M, Màu: Trắng', '750,000', 'https://lh3.googleusercontent.com/aida-public/AB6AXuCNPTodcpX81FDaSia6fbQMbHcwogkuCritgwqek94OPTdauvFa_drPmLbdbbTjQB4mWphihtLStInnvi2M-EYURoXpPOSW4eRFNVqWXPjE7uNQ2swpSxD4g0bODLkF0XKd2p4bijrJ49q_5bjm1BBX6Ms1t0zey6c4hSgSDWFjfCpbKw-5MAYLdkVdM_PhFdXiM2WwQ_CSp2JiXx5aQibreffoNcp5DQRzD6L_4FxIxp6_iWtNqgXpukwIkVt1QpgYHqMa6AOcMw', 1, primaryColor),
                const SizedBox(height: 16),
                // List Item 2
                _buildCartItem(context, 'Áo Hoodie Xanh', 'Size: L, Màu: Xanh Navy', '550,000', 'https://lh3.googleusercontent.com/aida-public/AB6AXuByFvSgR1d-uT-PrQHRXywOHh7bXILBrezItCpOabgQxN9zgUH4PvM6MBaH3a-ZTvpPZTg4PiMXVubjgwkIl3qoi8ga765aj6oGqmX8NiDe14OmlcxuAuiQOCNoQYMW4pCvy_lfWkJjtiznAJchSsZ252IM1gPjjZ7h9wszDhG30K-0jj0lHgzI--RV2tNcNYh8WPJ2J1W21dI-ii1gqojbQ2xLlwOazaCMvxj10bMRn6oD0Gqwec6u6yiktDkDlOCZqe-beB4C9g', 2, primaryColor),
                
                const SizedBox(height: 250), // Khoảng đệm cho Footer cố định
              ],
            ),
          ),
          // Sticky Footer for Summary and CTA
          _buildCartFooter(context, primaryColor, backgroundLight),
        ],
      ),
    );
  }

  // Widget con: Hiển thị từng mục sản phẩm trong giỏ hàng
  Widget _buildCartItem(
      BuildContext context,
      String name,
      String details,
      String price,
      String imageUrl,
      int quantity,
      Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // Giả lập shadow-sm
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            height: 96,
            width: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16))),
                    const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                  ],
                ),
                Text(details, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("đ$price", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                    // Quantity Control
                    Row(
                      children: [
                        _quantityButton('-'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w500)),
                        ),
                        _quantityButton('+'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget con: Nút điều chỉnh số lượng
  Widget _quantityButton(String text) {
    return Container(
      height: 28,
      width: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        shape: BoxShape.circle,
      ),
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }

  // Widget con: Footer cố định (Tổng kết & CTA)
  Widget _buildCartFooter(BuildContext context, Color primaryColor, Color backgroundLight) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          // Áp dụng backgroundLight và độ mờ (giả lập backdrop-blur)
          color: backgroundLight.withOpacity(0.9), 
          border: const Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1.0)),
        ),
        child: Column(
          children: [
            // Order Summary
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _summaryRow('Tạm tính', 'đ1,850,000', isTotal: false),
                  _summaryRow('Phí vận chuyển', 'Miễn phí', isTotal: false),
                  const SizedBox(height: 8),
                  _summaryRow('Tổng cộng', 'đ1,850,000', isTotal: true, primaryColor: primaryColor),
                ],
              ),
            ),
            // Checkout Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton(
                onPressed: () {}, // TODO: Navigate to Checkout
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Tiến hành thanh toán", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget con: Hàng tóm tắt chi phí
  Widget _summaryRow(String label, String value, {bool isTotal = false, Color? primaryColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14, color: isTotal ? Colors.black : Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.w500, fontSize: isTotal ? 16 : 14, color: isTotal ? primaryColor : Colors.black87)),
        ],
      ),
    );
  }
}