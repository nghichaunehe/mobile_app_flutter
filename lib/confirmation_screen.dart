import 'package:flutter/material.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy màu từ Theme
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundLight = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      // Top App Bar
      appBar: AppBar(
        title: const Text("Xác nhận đơn hàng", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: backgroundLight.withOpacity(0.8),
        elevation: 0.5,
      ),
      
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Success Message ---
                _buildSuccessMessage(primaryColor),

                const SizedBox(height: 32),

                // --- Order Summary Card ---
                _buildOrderSummaryCard(primaryColor),

                const SizedBox(height: 24),
                
                // --- Shipping & Payment Info Card ---
                _buildShippingPaymentCard(),

                const SizedBox(height: 24),

                // --- Total Cost Card ---
                _buildTotalCostCard(primaryColor),
              ],
            ),
          ),
          
          // Fixed Action Buttons Footer
          _buildActionFooter(context, primaryColor, backgroundLight),
        ],
      ),
    );
  }

  // --- WIDGETS CON ---

  Widget _buildSuccessMessage(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Check Mark Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor.withOpacity(0.2),
          ),
          child: Icon(Icons.check_circle, size: 50, color: primaryColor),
        ),
        
        const Padding(
          padding: EdgeInsets.only(top: 20.0, bottom: 8.0),
          child: Text(
            "Đặt hàng thành công!",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
        
        const Text(
          "Cảm ơn bạn đã mua sắm! Mã đơn hàng của bạn là #123456.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sản phẩm đã đặt",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          _buildOrderItem('Áo thun xanh navy', 'Size: L, Số lượng: 1', '550.000₫', 'https://lh3.googleusercontent.com/aida-public/AB6AXuDNS06eGUUFpnNi8lRIEgXtLNpWAJk0bAAzhlgOkadKDNixnWLRrlY6Oqfxb4u15WNSa3odnc2bk1RsApUfAs7Dj281JqANV5GkGSrB-yZdzTzr191BsoG92jZULhypTIWOo1xp7c8QhuBHUZkE7VZpdinMjNaS01u5mJlSsjtP-7ORUGdwKLXdwjKoIxbv0Has7W3QT3AEoJcjevme3rvsXX_5EifGMcO9aYoBX8Dz-b4jx3OIewFiIOhMlpic_2j_n_cy3OtFUg'),
          const SizedBox(height: 16),
          _buildOrderItem('Áo hoodie trắng', 'Size: M, Số lượng: 1', '720.000₫', 'https://lh3.googleusercontent.com/aida-public/AB6AXuBrFVmOBjttpbz4Q6sMbuKiSn07jnGpvEKM_MsL46y9r5t-GF1dXB5X6SVP9ujUGIXboCM58xmNwy8jjXEEbyAZhMqkG5S5klkjLHSXGNwtUQLPaGMPpTFHFJL5bcXglUJS3f5IF5OQGFZgVKe1spARXOYZjoNTro68CAPSGG6g7fmKGMjmL1564HLXA6ZlWdK7V-Cerz_6uqTzapUq-os_R4zFbcnhDXDUHeaOCTHm17Skjped-i_Hz4NbG8WzJ4Jw4A8Mb_7Xuw'),
        ],
      ),
    );
  }

  Widget _buildOrderItem(String name, String details, String price, String imageUrl) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87), overflow: TextOverflow.ellipsis),
              Text(details, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
        Text(price, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87)),
      ],
    );
  }
  
  Widget _buildShippingPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Địa chỉ
          const Text('Địa chỉ giao hàng', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 4),
          const Text('Nguyễn Văn A\n123 Đường ABC, Phường XYZ, Quận 1\nThành phố Hồ Chí Minh, 700000', style: TextStyle(fontSize: 16, color: Colors.black87)),
          
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 16),

          // Phương thức thanh toán
          const Text('Phương thức thanh toán', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 4),
          const Text('Thanh toán khi nhận hàng (COD)', style: TextStyle(fontSize: 16, color: Colors.black87)),
        ],
      ),
    );
  }
  
  Widget _buildTotalCostCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _summaryRow('Tạm tính', '1.270.000₫', isTotal: false),
          _summaryRow('Phí vận chuyển', '30.000₫', isTotal: false),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1, color: Colors.grey),
          ),
          _summaryRow('Tổng cộng', '1.300.000₫', isTotal: true, primaryColor: primaryColor),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false, Color? primaryColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 18 : 16,
              color: isTotal ? Colors.black87 : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 18 : 16,
              color: isTotal ? primaryColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionFooter(BuildContext context, Color primaryColor, Color backgroundLight) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Dùng backdrop-blur giả lập bằng cách làm màu nền mờ
          color: backgroundLight.withOpacity(0.9), 
          border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: Column(
          children: [
            // Nút 1: Tiếp tục mua sắm
            ElevatedButton(
              onPressed: () {}, 
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Tiếp tục mua sắm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 8),

            // Nút 2: Xem chi tiết đơn hàng (Dùng primary/20)
            ElevatedButton(
              onPressed: () {}, 
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor.withOpacity(0.2),
                foregroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("Xem chi tiết đơn hàng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}