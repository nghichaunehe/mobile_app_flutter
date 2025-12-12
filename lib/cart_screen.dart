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
  
  // UPDATE 1: Biến lưu các ID của item đang được tick chọn
  final Set<int> _selectedItemIds = {}; 

  @override
  void initState() {
    super.initState();
    _fetchCartData();
  }

  Future<void> _fetchCartData() async {
    setState(() => _isLoading = true);
    final data = await _cartService.getCart();
    
    setState(() {
      _cartData = data;
      _isLoading = false;
      // UPDATE 2: Mặc định khi load xong thì chọn tất cả (hoặc không chọn tùy em)
      if (_cartData != null) {
        _selectedItemIds.clear();
        for (var item in _cartData!.items) {
          _selectedItemIds.add(item.id);
        }
      }
    });
  }

  // UPDATE 3: Hàm tính tổng tiền dựa trên các item ĐƯỢC CHỌN
  double _calculateTotal() {
    if (_cartData == null) return 0;
    double total = 0;
    for (var item in _cartData!.items) {
      if (_selectedItemIds.contains(item.id)) {
        total += item.product.price * item.quantity;
      }
    }
    return total;
  }

  // UPDATE 4: Logic tăng giảm số lượng
  Future<void> _updateQuantity(int cartItemId, int change) async {
    if (_cartData == null) return;
    
    // Tìm item trong list local
    final index = _cartData!.items.indexWhere((element) => element.id == cartItemId);
    if (index == -1) return;

    final currentItem = _cartData!.items[index];
    final newQuantity = currentItem.quantity + change;

    // Không cho giảm dưới 1
    if (newQuantity < 1) return;

    // TODO: Gọi API update số lượng lên Server ở đây
    // await _cartService.updateQuantity(cartItemId, newQuantity);

    // Cập nhật UI Local ngay lập tức
    setState(() {
      _cartData!.items[index].quantity = newQuantity;
    });
  }

  Future<void> _removeItem(int cartItemId) async {
    bool success = await _cartService.removeCartItem(cartItemId);
    if (success) {
      // Xóa xong thì bỏ chọn nó khỏi list selected luôn
      _selectedItemIds.remove(cartItemId); 
      _fetchCartData();
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
                            const SizedBox(height: 150),
                          ],
                        ),
                      ),
                    ),
                    
                    _buildCartFooter(context, primaryColor, backgroundLight, currencyFormatter),
                  ],
                ),
    );
  }

  Widget _buildCartItem(
      BuildContext context,
      CartItemModel item, 
      NumberFormat formatter,
      Color primaryColor) {
    
    Widget imageWidget;
    if (item.product.imageBase64 != null && item.product.imageBase64!.startsWith('http')) {
       imageWidget = Image.network(item.product.imageBase64!, fit: BoxFit.cover);
    } else {
       imageWidget = const Icon(Icons.image, size: 40, color: Colors.grey);
    }

    // UPDATE 5: Bọc trong Row để thêm Checkbox
    return Row(
      children: [
        // Checkbox ở đầu
        Checkbox(
          activeColor: primaryColor,
          value: _selectedItemIds.contains(item.id),
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedItemIds.add(item.id);
              } else {
                _selectedItemIds.remove(item.id);
              }
            });
          },
        ),
        
        // Phần hiển thị item cũ
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12), // Giảm padding chút cho đỡ chật
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 80, // Giảm size ảnh chút
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: imageWidget,
                ),
                const SizedBox(width: 12),
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
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => _removeItem(item.id),
                            child: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                          ),
                        ],
                      ),
                      Text("Size: ${item.size ?? '-'}, Màu: ${item.color ?? '-'}", 
                          style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${formatter.format(item.product.price)}₫", 
                            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)
                          ),
                          
                          // UPDATE 6: Logic nút tăng giảm
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _updateQuantity(item.id, -1),
                                child: _quantityButton('-'),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w500)),
                              ),
                              InkWell(
                                onTap: () => _updateQuantity(item.id, 1),
                                child: _quantityButton('+'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
        border: Border.all(color: Colors.grey[300]!) // Thêm viền cho rõ
      ),
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildCartFooter(BuildContext context, Color primaryColor, Color backgroundLight, NumberFormat formatter) {
    // UPDATE 7: Gọi hàm tính toán mới thay vì lấy total từ API
    double total = _calculateTotal();

    return Positioned(
      bottom: 0, left: 0, right: 0,
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
                  _summaryRow('Đã chọn', "${_selectedItemIds.length} sản phẩm", isTotal: false), // Thêm dòng đếm
                  _summaryRow('Tổng cộng', "${formatter.format(total)}₫", isTotal: true, primaryColor: primaryColor),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton(
                onPressed: _selectedItemIds.isEmpty ? null : () { // Disable nếu không chọn gì
                    // Navigate to Checkout với danh sách items đã chọn
                    // Navigator.push Named... arguments: _selectedItemIds
                }, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: Colors.grey, // Màu khi disable
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