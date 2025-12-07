import 'package:flutter/material.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy màu từ Theme
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundLight = Theme.of(context).scaffoldBackgroundColor;

    return GestureDetector(
      // Cho phép ẩn bàn phím khi bấm ra ngoài
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // Top App Bar
        appBar: AppBar(
          title: const Text("Thanh toán", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: backgroundLight.withOpacity(0.8),
          elevation: 0.5,
        ),
        
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Delivery Information Section
              _buildDeliveryInfoSection(context, primaryColor),
              
              // Payment Method Section
              _buildPaymentMethodSection(context, primaryColor),
              
              // Order Summary Section
              _buildOrderSummarySection(context, primaryColor),
              
              const SizedBox(height: 100), // Padding cho Footer CTA cố định
            ],
          ),
        ),
        
        // Bottom CTA Bar (Footer cố định)
        bottomNavigationBar: _buildCheckoutFooter(context, primaryColor, backgroundLight),
      ),
    );
  }

  // --- WIDGETS CON ---

  Widget _buildDeliveryInfoSection(BuildContext context, Color primaryColor) {
    // Sử dụng Form để có thể thêm validation sau này
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
            child: Text("Thông tin giao hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                // Họ và tên
                _buildInputLabel("Họ và tên", "Nhập họ và tên", keyboardType: TextInputType.name),
                const SizedBox(height: 16),
                
                // Số điện thoại
                _buildInputLabel("Số điện thoại", "Nhập số điện thoại", keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                
                // Địa chỉ (Textarea)
                _buildInputLabel("Địa chỉ", "Nhập địa chỉ của bạn", isMultiLine: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context, Color primaryColor) {
    // Dùng StatefulWidget nếu bạn muốn cập nhật trạng thái chọn (checked)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: Text("Phương thức thanh toán", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // Thanh toán khi nhận hàng (COD)
              _buildPaymentOption(
                "Thanh toán khi nhận hàng",
                Icons.local_shipping,
                primaryColor,
                isSelected: true,
              ),
              const SizedBox(height: 12),
              // Chuyển khoản ngân hàng
              _buildPaymentOption(
                "Chuyển khoản ngân hàng",
                Icons.account_balance,
                primaryColor,
              ),
              const SizedBox(height: 12),
              // Thẻ Tín dụng/Ghi nợ
              _buildPaymentOption(
                "Thẻ Tín dụng/Ghi nợ",
                Icons.credit_card,
                primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummarySection(BuildContext context, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: Text("Tổng kết đơn hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _summaryRow("Tạm tính (3 sản phẩm)", "1.250.000đ", isTotal: false, color: Colors.grey[600]),
                _summaryRow("Phí vận chuyển", "30.000đ", isTotal: false, color: Colors.grey[600]),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(height: 1, color: Colors.grey, endIndent: 0, indent: 0),
                ),
                _summaryRow("Tổng cộng", "1.280.000đ", isTotal: true, primaryColor: primaryColor),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // --- HELPERS CẤP THẤP ---

  Widget _buildInputLabel(String label, String hint, {bool isMultiLine = false, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
        isMultiLine
            ? TextFormField(
                maxLines: 4,
                decoration: _inputDecoration(hint).copyWith(
                  contentPadding: const EdgeInsets.all(15),
                  // Điều chỉnh minHeight cho textarea
                  fillColor: Colors.white, 
                ),
              )
            : TextFormField(
                keyboardType: keyboardType,
                decoration: _inputDecoration(hint),
              ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final primaryColor = Theme.of(context).primaryColor;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
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
    );
  }
  
  Widget _buildPaymentOption(String title, IconData icon, Color primaryColor, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? primaryColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.radio_button_checked, size: 20, color: isSelected ? primaryColor : Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isSelected ? primaryColor : Colors.black87)),
          ),
          Icon(icon, size: 24, color: isSelected ? primaryColor : Colors.grey),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false, Color? primaryColor, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 15,
              color: color ?? Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 18 : 15,
              color: isTotal ? primaryColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutFooter(BuildContext context, Color primaryColor, Color backgroundLight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundLight.withOpacity(0.9),
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: ElevatedButton(
        onPressed: () {}, // TODO: Xử lý Thanh toán
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8,
          shadowColor: primaryColor.withOpacity(0.3),
        ),
        child: const Text(
          "Hoàn tất thanh toán",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}