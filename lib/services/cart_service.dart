import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// --- MODELS ---

class CartItemModel {
  final int id;
  int quantity;
  final String? size;
  final String? color;
  final ProductModel product;

  CartItemModel({
    required this.id,
    required this.quantity,
    this.size,
    this.color,
    required this.product,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'],
      quantity: json['quantity'],
      size: json['size'],
      color: json['color'],
      product: ProductModel.fromJson(json['product']),
    );
  }
}

class ProductModel {
  final int id;
  final String name;
  final dynamic price; // Có thể là int hoặc string từ BE
  final String? imageBase64; // Giả sử BE trả về field này hoặc url

  ProductModel({required this.id, required this.name, required this.price, this.imageBase64});

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      imageBase64: json['imageBase64'] ?? json['imageUrl'] ?? '', // Map tùy theo response thực tế
    );
  }
}

class CartResponse {
  final List<CartItemModel> items;
  final double totalPrice;

  CartResponse({required this.items, required this.totalPrice});

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    List<CartItemModel> itemsList = list.map((i) => CartItemModel.fromJson(i)).toList();
    
    return CartResponse(
      items: itemsList,
      totalPrice: double.parse(json['totalPrice'].toString()),
    );
  }
}

// --- SERVICE ---

class CartService {
  // Thay đổi IP này tùy môi trường (Android Emulator dùng 10.0.2.2, iOS dùng localhost)
  static const String baseUrl = 'http://localhost:3001/cart'; 

  // Hàm lấy Header kèm Token Authorization
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? ''; 
    
    // 👇 THÊM DÒNG NÀY ĐỂ DEBUG 👇
    print("Token đang dùng để gọi API: $token"); 
    // 👆 NẾU NÓ RỖNG => BẠN CHƯA LƯU TOKEN LÚC LOGIN
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. Lấy giỏ hàng
  Future<CartResponse?> getCart() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(baseUrl), headers: headers);

      if (response.statusCode == 200) {
        return CartResponse.fromJson(jsonDecode(response.body));
      } else {
        print('Lỗi lấy giỏ hàng: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Lỗi kết nối: $e');
      return null;
    }
  }

  // 2. Thêm vào giỏ hàng
  Future<bool> addToCart({
    required int productId,
    required int quantity,
    required String size,
    required String color,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        "userId": "temp", // Backend sẽ override bằng token, nhưng DTO yêu cầu field này
        "productId": productId,
        "quantity": quantity,
        "size": size,
        "color": color
      });

      final response = await http.post(
        Uri.parse('$baseUrl/add'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('Lỗi thêm giỏ hàng: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Err add cart: $e');
      return false;
    }
  }

  // 3. Xóa item
  Future<bool> removeCartItem(int cartItemId) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        "cartItemId": cartItemId
      });

      // API backend dùng @Delete('remove') với @Body,
      // nhưng chuẩn RESTful DELETE thường không có Body.
      // Flutter http.delete có hỗ trợ body nhưng cẩn thận server config.
      final request = http.Request('DELETE', Uri.parse('$baseUrl/remove'));
      request.headers.addAll(headers);
      request.body = body;

      final response = await request.send();

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // 4. Tạo đơn hàng (Order)
  Future<OrderResult> createOrder({
    required List<int> productIds,
    required String shippingAddress,
    String? notes,
  }) async {
    const String orderUrl = 'https://coral-interjugal-xochitl.ngrok-free.dev/orders/create';

    try {
      final headers = await _getHeaders();
      // Thêm header cho ngrok
      headers['ngrok-skip-browser-warning'] = 'true';

      final body = jsonEncode({
        "productIds": productIds,
        "shippingAddress": shippingAddress,
        "notes": notes ?? "",
      });

      print('Order request - URL: $orderUrl');
      print('Order request - Headers: $headers');
      print('Order request - Body: $body');

      final response = await http.post(
        Uri.parse(orderUrl),
        headers: headers,
        body: body,
      );

      print('Order response - Status: ${response.statusCode}');
      print('Order response - Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return OrderResult(
          success: true,
          message: 'Đặt hàng thành công!',
          orderId: data['orderId']?.toString(),
          paymentUrl: data['paymentUrl'],
        );
      } else {
        final errorData = jsonDecode(response.body);
        return OrderResult(
          success: false,
          message: errorData['message'] ?? 'Đặt hàng thất bại. Vui lòng thử lại!',
        );
      }
    } catch (e) {
      print('Lỗi tạo đơn hàng: $e');
      return OrderResult(
        success: false,
        message: 'Lỗi kết nối. Vui lòng kiểm tra mạng và thử lại!',
      );
    }
  }
}

// Model cho kết quả tạo order
class OrderResult {
  final bool success;
  final String message;
  final String? orderId;
  final String? paymentUrl;

  OrderResult({
    required this.success,
    required this.message,
    this.orderId,
    this.paymentUrl,
  });
}