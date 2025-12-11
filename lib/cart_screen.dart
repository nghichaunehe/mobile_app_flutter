import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/services/cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  CartResponse? _cartData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCartData();
  }

  // Hàm gọi API lấy dữ liệu
  Future<void> _fetchCartData() async {
    setState(() => _isLoading = true);
    final data = await _cartService.getCart();
    setState(() {
      _cartData = data;
      _isLoading = false;
    });
  }

  // Hàm xóa item
  Future<void> _removeItem(int cartItemId) async {
    bool success = await _cartService.removeCartItem(cartItemId);
    if (success) {
      _fetchCartData(); // Load lại danh sách sau khi xóa
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundLight = Theme.of(context).scaffoldBackgroundColor;
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Giỏ hàng", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: backgroundLight.withOpacity(0.8),
        elevation: 0.5,
      ),
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_cartData == null || _cartData!.items.isEmpty)
              ? const Center(child: Text("Giỏ hàng trống"))
              : Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: _fetchCartData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Render list items từ API
                            ..._cartData!.items.map((item) {
                              return Column(
                                children: [
                                  _buildCartItem(
                                    context, 
                                    item, 
                                    currencyFormatter, 
                                    primaryColor
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            }).toList(),

                            const SizedBox(height: 150), // Khoảng đệm cho Footer
                          ],
                        ),
                      ),
                    ),
                    
                    // Footer tính tổng tiền
                    _buildCartFooter(context, primaryColor, backgroundLight, currencyFormatter),
                  ],
                ),
    );
  }

  Widget _buildCartItem(
      BuildContext context,
      CartItemModel item, // Nhận vào Model
      NumberFormat formatter,
      Color primaryColor) {
    
    // Xử lý ảnh: Check base64 hay url
    Widget imageWidget;
    if (item.product.imageBase64 != null && item.product.imageBase64!.startsWith('http')) {
       imageWidget = Image.network(item.product.imageBase64!, fit: BoxFit.cover);
    } else {
       // Nếu là base64 thật sự hoặc placeholder
       imageWidget = const Icon(Icons.image, size: 40, color: Colors.grey);
       // TODO: Nếu BE trả base64 raw string thì dùng Image.memory(base64Decode(...))
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 96,
            width: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            clipBehavior: Clip.hardEdge,
            child: imageWidget,
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
                    Expanded(
                      child: Text(
                        item.product.name, 
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => _removeItem(item.id),
                      child: const Icon(Icons.delete_outline, size: 24, color: Colors.redAccent),
                    ),
                  ],
                ),
                Text("Size: ${item.size ?? '-'}, Màu: ${item.color ?? '-'}", 
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${formatter.format(double.parse(item.product.price.toString()))}₫", 
                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)
                    ),
                    Row(
                      children: [
                        _quantityButton('-'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w500)),
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

  Widget _buildCartFooter(BuildContext context, Color primaryColor, Color backgroundLight, NumberFormat formatter) {
    // Nếu chưa load xong hoặc không có dữ liệu thì hiện 0
    double total = _cartData?.totalPrice ?? 0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundLight.withOpacity(0.95), 
          border: const Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1.0)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _summaryRow('Tạm tính', "${formatter.format(total)}₫", isTotal: false),
                  _summaryRow('Phí vận chuyển', 'Miễn phí', isTotal: false),
                  const SizedBox(height: 8),
                  _summaryRow('Tổng cộng', "${formatter.format(total)}₫", isTotal: true, primaryColor: primaryColor),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton(
                onPressed: () {
                   // Navigate to Checkout
                }, 
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