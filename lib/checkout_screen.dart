import 'package:flutter/material.dart';
import 'dart:convert'; // Dùng để encode/decode JSON
import 'package:http/http.dart' as http; // Import thư viện HTTP

// !!! CẬP NHẬT URL API !!!
// Thay đổi port nếu bạn dùng NestJS (thường là 3000) hoặc Dart Frog (thường là 8080).
// Dùng http://10.0.2.2:8080 nếu chạy trên Android Emulator.
const String API_BASE_URL = "https://coral-interjugal-xochitl.ngrok-free.dev"; 

// Chuyển từ StatelessWidget sang StatefulWidget để quản lý trạng thái form và lựa chọn
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Controller và Key cho Form
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController(text: 'Nguyễn Văn A'); 
  final TextEditingController _phoneController = TextEditingController(text: '0901234567');
  final TextEditingController _addressController = TextEditingController(text: 'Số 1, đường 3/2, Quận 10, TP HCM');

  // Biến trạng thái cho Phương thức thanh toán (COD, BANK_TRANSFER, CARD)
  String _selectedPaymentMethod = 'COD'; // Mặc định là COD
  bool _isLoading = false;

  // Dữ liệu giả lập (thực tế sẽ được truyền từ CartScreen)
  final double _subTotal = 1250000;
  final double _shippingFee = 30000;
  double get _totalAmount => _subTotal + _shippingFee;

  // Chi tiết sản phẩm giả lập (để gửi lên API)
  final List<Map<String, dynamic>> _cartItems = const [
    {'product_id': 1, 'quantity': 1, 'price': 250000},
    {'product_id': 2, 'quantity': 2, 'price': 500000},
  ];
  
  // Hàm xử lý Đặt hàng (Gọi API POST /orders)
  Future<void> _handleCheckout() async {
    // 1. Validate Form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // 2. Bắt đầu Loading
    setState(() {
      _isLoading = true;
    });

    final url = '$API_BASE_URL/orders';
    final body = json.encode({
      'name': _nameController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
      'payment_method': _selectedPaymentMethod, // Gửi phương thức đã chọn
      'total_amount': _totalAmount,
      'items': _cartItems, // Gửi chi tiết giỏ hàng
      'user_id': 123, // Giả định ID người dùng đã đăng nhập
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      final responseData = json.decode(response.body);
      final success = response.statusCode == 200;

      // Xử lý thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? "Đặt hàng thành công! Mã đơn hàng: ${responseData['order_id']}" 
            : responseData['message'] ?? "Đặt hàng thất bại. Vui lòng thử lại."),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        // Chuyển hướng đến màn hình xác nhận sau khi đặt hàng thành công
        // Navigator.pushNamedAndRemoveUntil(context, '/confirmation', (route) => false);
      }

    } catch (error) {
      // Lỗi kết nối
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lỗi kết nối mạng hoặc server không phản hồi."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // 3. Kết thúc Loading
      setState(() {
        _isLoading = false;
      });
    }
  }

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
    // Sử dụng Form key
    return Form(
      key: _formKey,
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
                _buildInputLabel("Họ và tên", "Nhập họ và tên", controller: _nameController, keyboardType: TextInputType.name),
                const SizedBox(height: 16),
                
                // Số điện thoại
                _buildInputLabel("Số điện thoại", "Nhập số điện thoại", controller: _phoneController, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                
                // Địa chỉ (Textarea)
                _buildInputLabel("Địa chỉ", "Nhập địa chỉ của bạn", controller: _addressController, isMultiLine: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context, Color primaryColor) {
    // Đã chuyển logic lựa chọn vào _buildPaymentOption
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
                'COD', // paymentKey
                primaryColor,
              ),
              const SizedBox(height: 12),
              // Chuyển khoản ngân hàng
              _buildPaymentOption(
                "Chuyển khoản ngân hàng",
                Icons.account_balance,
                'BANK_TRANSFER', // paymentKey
                primaryColor,
              ),
              const SizedBox(height: 12),
              // Thẻ Tín dụng/Ghi nợ
              _buildPaymentOption(
                "Thẻ Tín dụng/Ghi nợ",
                Icons.credit_card,
                'CARD', // paymentKey
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
                _summaryRow("Tạm tính (${_cartItems.length} sản phẩm)", "${_subTotal.toStringAsFixed(0)}đ", isTotal: false, color: Colors.grey[600]),
                _summaryRow("Phí vận chuyển", "${_shippingFee.toStringAsFixed(0)}đ", isTotal: false, color: Colors.grey[600]),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(height: 1, color: Colors.grey, endIndent: 0, indent: 0),
                ),
                _summaryRow("Tổng cộng", "${_totalAmount.toStringAsFixed(0)}đ", isTotal: true, primaryColor: primaryColor),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // --- HELPERS CẤP THẤP (Đã cập nhật để dùng Controller và Validation) ---

  Widget _buildInputLabel(String label, String hint, {TextEditingController? controller, bool isMultiLine = false, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
        TextFormField(
            controller: controller,
            maxLines: isMultiLine ? 4 : 1,
            keyboardType: keyboardType,
            decoration: _inputDecoration(hint).copyWith(
              contentPadding: isMultiLine ? const EdgeInsets.all(15) : const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
              fillColor: Colors.white, 
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập $label';
              }
              // Thêm validation cơ bản cho số điện thoại
              if (keyboardType == TextInputType.phone && !RegExp(r'^[0-9]+$').hasMatch(value)) {
                  return 'Số điện thoại không hợp lệ.';
              }
              return null;
            },
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
  
  Widget _buildPaymentOption(String title, IconData icon, String paymentKey, Color primaryColor) {
    bool isSelected = _selectedPaymentMethod == paymentKey; // Dùng biến trạng thái
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = paymentKey; // Cập nhật trạng thái khi chọn
        });
      },
      child: Container(
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
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 20, color: isSelected ? primaryColor : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isSelected ? primaryColor : Colors.black87)),
            ),
            Icon(icon, size: 24, color: isSelected ? primaryColor : Colors.grey),
          ],
        ),
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
        onPressed: _isLoading ? null : _handleCheckout, // Gọi hàm đặt hàng
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8,
          shadowColor: primaryColor.withOpacity(0.3),
        ),
        child: _isLoading 
            ? const SizedBox( // Hiển thị vòng tròn loading
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              )
            : const Text(
                "Hoàn tất thanh toán",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
    );
  }
}