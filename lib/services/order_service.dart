import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// --- MODELS ---

class OrderModel {
  final int id;
  final DateTime createdAt;
  final String totalPrice;
  final String status;
  final String shippingAddress;
  final String? notes;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.createdAt,
    required this.totalPrice,
    required this.status,
    required this.shippingAddress,
    this.notes,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    return OrderModel(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      totalPrice: json['totalPrice'].toString(),
      status: json['status'] ?? 'PENDING',
      shippingAddress: json['shippingAddress'] ?? '',
      notes: json['notes'],
      items: itemsList.map((i) => OrderItemModel.fromJson(i)).toList(),
    );
  }

  // Lấy tổng số lượng sản phẩm
  int get totalQuantity {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Lấy tên status hiển thị
  String get statusDisplay {
    switch (status) {
      case 'PENDING':
        return 'Chờ thanh toán';
      case 'PAID':
        return 'Đã thanh toán';
      case 'PROCESSING':
        return 'Đang xử lý';
      case 'SHIPPING':
        return 'Đang giao hàng';
      case 'COMPLETED':
        return 'Hoàn thành';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}

class OrderItemModel {
  final int id;
  final int quantity;
  final String price;
  final OrderProductModel product;

  OrderItemModel({
    required this.id,
    required this.quantity,
    required this.price,
    required this.product,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      quantity: json['quantity'] ?? 1,
      price: json['price'].toString(),
      product: OrderProductModel.fromJson(json['product']),
    );
  }
}

class OrderProductModel {
  final int id;
  final String name;
  final dynamic price;
  final String? imageBase64;
  final String? description;

  OrderProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.imageBase64,
    this.description,
  });

  factory OrderProductModel.fromJson(Map<String, dynamic> json) {
    return OrderProductModel(
      id: json['id'],
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      imageBase64: json['imageBase64'],
      description: json['description'],
    );
  }
}

// --- SERVICE ---

class OrderService {
  static const String baseUrl = 'https://coral-interjugal-xochitl.ngrok-free.dev/orders';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  // Lấy danh sách đơn hàng của user
  Future<List<OrderModel>> getMyOrders() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/my-orders'),
        headers: headers,
      );

      print('Orders response - Status: ${response.statusCode}');
      print('Orders response - Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => OrderModel.fromJson(json)).toList();
      } else {
        print('Lỗi lấy đơn hàng: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Lỗi kết nối: $e');
      return [];
    }
  }

  // Lấy chi tiết đơn hàng
  Future<OrderModel?> getOrderDetail(int orderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$orderId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return OrderModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Lỗi lấy chi tiết đơn hàng: $e');
      return null;
    }
  }
}
