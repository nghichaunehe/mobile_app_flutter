import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Giả định bạn có các Models và Services này
import '/services/cart_service.dart';
import '/services/api_service.dart';
import 'payment_webview_screen.dart'; 
import 'secure_storage_manager.dart';
// import 'path/to/models/cart_response.dart'; 
// import 'path/to/models/cart_item_model.dart'; 

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final ApiService _apiService = ApiService();
  CartResponse? _cartData;
  bool _isLoading = true;
  bool _isOrdering = false; // Trạng thái đang đặt hàng
  bool _isLoadingAddresses = false;

  // UPDATE 1: Biến lưu các ID của item đang được tick chọn
  final Set<int> _selectedItemIds = {};

  // Danh sách địa chỉ và quản lý lựa chọn
  List<ShippingAddressModel> _shippingAddresses = [];
  ShippingAddressModel? _selectedAddress;
  bool _useCustomAddress = false;

  // Controllers cho dialog đặt hàng
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController(); 
  
  // UPDATE: Định dạng tiền tệ chính xác (Locale vi_VN, không số thập phân)
  final currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫', // Ký hiệu tiền tệ
    decimalDigits: 0, 
  );

  @override
  void initState() {
    super.initState();
    _fetchCartData();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _recipientController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchCartData() async {
    setState(() => _isLoading = true);
    final data = await _cartService.getCart();

    setState(() {
      _cartData = data;
      _isLoading = false;
      
      // UPDATE 2: Mặc định khi load xong thì chọn tất cả
      _selectedItemIds.clear();
      if (_cartData != null) {
        // Chỉ thêm vào set nếu list items không rỗng
        if (_cartData!.items.isNotEmpty) {
          for (var item in _cartData!.items) {
            _selectedItemIds.add(item.id);
          }
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
        // Chú ý: Vì giá là double/num, nên tính toán trực tiếp
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
    
    // Tối ưu UI: Cập nhật UI Local ngay lập tức 
    setState(() {
      _cartData!.items[index].quantity = newQuantity;
    });

    // TODO: Gọi API update số lượng lên Server ở đây
    // Nếu API gọi thành công thì giữ nguyên, nếu thất bại thì rollback lại số lượng cũ.
    // await _cartService.updateQuantity(cartItemId, newQuantity);
  }

  Future<void> _removeItem(int cartItemId) async {
    // Tạm thời xóa khỏi UI ngay lập tức
    setState(() {
        _cartData!.items.removeWhere((item) => item.id == cartItemId);
        _selectedItemIds.remove(cartItemId);
    });

    // Gọi API xóa
    bool success = await _cartService.removeCartItem(cartItemId);
    
    // Nếu API thất bại, bạn có thể cân nhắc re-fetch hoặc hiển thị lỗi
    if (!success) {
      // Logic xử lý khi xóa thất bại (tùy chọn)
      // _fetchCartData(); // Cần fetch lại để đồng bộ với server
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa sản phẩm thất bại. Vui lòng thử lại!'))
        );
      }
    }
    // Nếu thành công thì không cần fetch lại toàn bộ mà giữ nguyên state đã xóa.
  }

  Future<void> _loadShippingAddresses() async {
    setState(() {
      _isLoadingAddresses = true;
    });

    try {
      final response = await _apiService.get('/user/me/addresses');

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final addresses = data.map((e) => ShippingAddressModel.fromJson(e)).toList();

        ShippingAddressModel? defaultAddress;
        if (addresses.isNotEmpty) {
          defaultAddress = addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => addresses.first,
          );
        }

        setState(() {
          _shippingAddresses = addresses;
          _isLoadingAddresses = false;
        });

        if (defaultAddress != null) {
          _selectAddress(defaultAddress, notify: false);
        } else {
          setState(() {
            _selectedAddress = null;
            _useCustomAddress = true;
          });
          _addressController.clear();
          _recipientController.clear();
          _phoneController.clear();
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoadingAddresses = false;
        });
        await _handleUnauthorized();
      } else {
        setState(() {
          _isLoadingAddresses = false;
        });
        _showSnack('Không tải được danh sách địa chỉ');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingAddresses = false;
      });
      _showSnack('Lỗi tải địa chỉ: $e');
    }
  }

  // Cập nhật controller khi chọn địa chỉ
  void _selectAddress(ShippingAddressModel? address, {bool notify = true}) {
    void applySelection() {
      _selectedAddress = address;
      if (address != null) {
        _useCustomAddress = false;
        _addressController.text = address.address;
        _recipientController.text = address.recipientName;
        _phoneController.text = address.phone;
      } else {
        _selectedAddress = null;
        _useCustomAddress = true;
        _addressController.clear();
        _recipientController.clear();
        _phoneController.clear();
      }
    }

    if (notify) {
      setState(applySelection);
    } else {
      applySelection();
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleUnauthorized() async {
    await _apiService.logout();
    await SecureStorageManager.deleteJwt();

    if (!mounted) {
      return;
    }

    _showSnack('Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.');
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _checkOrderStatus(dynamic orderId) async {
    if (orderId == null) {
      _showSnack('Không thể kiểm tra trạng thái đơn hàng.');
      return;
    }

    try {
      final response = await _apiService.get('/orders/$orderId');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String status = data['status'] ?? '';

        // Refresh lại giỏ hàng
        await _fetchCartData();

        if (!mounted) return;

        if (status == 'COMPLETED') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Chúc mừng! Đơn hàng của bạn đã được thanh toán thành công!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        } else if (status == 'PENDING') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đơn hàng #$orderId đang chờ xử lý'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Trạng thái đơn hàng: $status'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (response.statusCode == 401) {
        await _handleUnauthorized();
      } else {
        _showSnack('Không thể kiểm tra trạng thái đơn hàng.');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Lỗi khi kiểm tra đơn hàng: $e');
    }
  }

  // Logic Checkbox "Chọn tất cả"
  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        if (_cartData != null) {
          _selectedItemIds.clear();
          for (var item in _cartData!.items) {
            _selectedItemIds.add(item.id);
          }
        }
      } else {
        _selectedItemIds.clear();
      }
    });
  }
  
  // Kiểm tra xem tất cả items đã được chọn chưa
  bool get _isAllSelected {
    if (_cartData == null || _cartData!.items.isEmpty) return false;
    return _selectedItemIds.length == _cartData!.items.length;
  }

  // Hiển thị dialog nhập địa chỉ và ghi chú để đặt hàng
  Future<void> _showOrderDialog() async {
    final primaryColor = Theme.of(context).primaryColor;

    await _loadShippingAddresses();

    if (!mounted) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              title: const Text('Thông tin đặt hàng'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hiển thị danh sách địa chỉ đã lưu
                    if (_shippingAddresses.isNotEmpty) ...[
                      const Text('Địa chỉ đã lưu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      _isLoadingAddresses
                          ? const SizedBox(
                              height: 40,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : Column(
                              children: _shippingAddresses.map((addr) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: RadioListTile<ShippingAddressModel>(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(addr.address, style: const TextStyle(fontSize: 13)),
                                    subtitle: Text('${addr.recipientName} | ${addr.phone}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    value: addr,
                                    groupValue: _useCustomAddress ? null : _selectedAddress,
                                    onChanged: (val) {
                                      setModalState(() => _selectAddress(val));
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 12),
                      Divider(color: Colors.grey[300]),
                      const SizedBox(height: 12),
                    ] else
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text('Chưa có địa chỉ đã lưu', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    // Toggle nhập địa chỉ tùy chỉnh
                    if (_shippingAddresses.isNotEmpty)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Nhập địa chỉ khác', style: TextStyle(fontSize: 13)),
                        value: _useCustomAddress,
                        onChanged: (val) {
                          setModalState(() {
                            _useCustomAddress = val ?? false;
                            if (_useCustomAddress) {
                              _addressController.clear();
                              _recipientController.clear();
                              _phoneController.clear();
                            }
                          });
                        },
                      )
                    else
                      const SizedBox.shrink(),
                    const SizedBox(height: 12),
                    // Hiển thị fields nhập khi chọn custom hoặc không có địa chỉ lưu
                    if (_useCustomAddress || _shippingAddresses.isEmpty) ...[
                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ giao hàng *',
                          hintText: 'Nhập địa chỉ giao hàng',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _recipientController,
                        decoration: const InputDecoration(
                          labelText: 'Tên người nhận (tùy chọn)',
                          hintText: 'Ví dụ: Nguyễn Văn A',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại (tùy chọn)',
                          hintText: 'Ví dụ: 090...',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Ghi chú (luôn hiển thị)
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú',
                        hintText: 'Ví dụ: Gọi trước 30 phút',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: _isOrdering ? null : () => _submitOrder(context),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  child: _isOrdering
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Xác nhận', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Xử lý gọi API đặt hàng
  Future<void> _submitOrder(BuildContext dialogContext) async {
    final address = _addressController.text.trim();

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập hoặc chọn địa chỉ giao hàng!')),
      );
      return;
    }

    setState(() => _isOrdering = true);

    // Lấy danh sách productId từ các item được chọn
    final List<int> productIds = _cartData!.items
        .where((item) => _selectedItemIds.contains(item.id))
        .map((item) => item.id)
        .toList();

    // Chuẩn bị dữ liệu để tạo đơn
    final result = await _cartService.createOrder(
      productIds: productIds,
      shippingAddress: address,
      recipientName: _recipientController.text.trim().isNotEmpty ? _recipientController.text.trim() : null,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      shippingAddressId: !_useCustomAddress && _selectedAddress != null ? _selectedAddress!.id : null,
      notes: _notesController.text.trim(),
    );

    setState(() => _isOrdering = false);

    // Đóng dialog
    if (dialogContext.mounted) {
      Navigator.pop(dialogContext);
    }

    if (!mounted) return;

    if (result.success && result.paymentUrl != null) {
      _addressController.clear();
      _recipientController.clear();
      _phoneController.clear();
      _notesController.clear();
      _selectedAddress = null;
      _useCustomAddress = false;

      // Mở webview để thanh toán VNPay và đợi khi popup đóng
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebviewScreen(paymentUrl: result.paymentUrl!),
        ),
      );

      if (!mounted) return;

      // Sau khi popup đóng, gọi API kiểm tra trạng thái đơn hàng
      await _checkOrderStatus(result.orderId);
    } else if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundLight = Theme.of(context).scaffoldBackgroundColor;
    
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
                            // Thêm Checkbox Chọn tất cả
                            _buildSelectAllRow(primaryColor), 
                            const SizedBox(height: 16),
                            
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
                            const SizedBox(height: 150), // Khoảng trống cho footer
                          ],
                        ),
                      ),
                    ),

                    _buildCartFooter(context, primaryColor, backgroundLight, currencyFormatter),
                  ],
                ),
    );
  }
  
  // Widget mới: Hàng Chọn Tất Cả
  Widget _buildSelectAllRow(Color primaryColor) {
    if (_cartData == null || _cartData!.items.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Checkbox(
            activeColor: primaryColor,
            value: _isAllSelected,
            onChanged: _toggleSelectAll,
          ),
          const Text("Chọn tất cả", style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }


  Widget _buildCartItem(
      BuildContext context,
      CartItemModel item, 
      NumberFormat formatter, // Đã là currency formatter
      Color primaryColor) {

    Widget imageWidget;
    if (item.product.imageUrl != null && item.product.imageUrl!.startsWith('http')) {
       imageWidget = Image.network(
         item.product.imageUrl!, 
         fit: BoxFit.cover,
         errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 40, color: Colors.grey),
       );
    } else {
       imageWidget = const Icon(Icons.image, size: 40, color: Colors.grey);
    }

    // UPDATE 5: Bọc trong Row để thêm Checkbox
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checkbox ở đầu
        Padding(
          padding: const EdgeInsets.only(top: 28.0), // Căn chỉnh Checkbox
          child: Checkbox(
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
        ),

        // Phần hiển thị item cũ (Expanded để chiếm hết phần còn lại)
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
                            // Sửa: Dùng formatter đã thiết lập
                            formatter.format(item.product.price), 
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
    String formattedTotal = formatter.format(total); // Format tổng tiền
    int selectedCount = _selectedItemIds.length;

    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom), // Xử lý safe area
        decoration: BoxDecoration(
          color: backgroundLight.withOpacity(0.98), 
          border: const Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1.0)),
          boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _summaryRow('Đã chọn', "$selectedCount sản phẩm", isTotal: false), 
                  _summaryRow('Tổng cộng', formattedTotal, isTotal: true, primaryColor: primaryColor),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton(
                onPressed: selectedCount == 0 ? null : _showOrderDialog, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: Colors.grey, // Màu khi disable
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Thanh toán ($selectedCount)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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