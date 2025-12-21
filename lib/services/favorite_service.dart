import 'dart:convert';
import 'api_service.dart';

class FavoriteService {
  final ApiService _apiService = ApiService();

  // Lấy danh sách sản phẩm yêu thích
  Future<List<FavoriteProduct>> getFavorites() async {
    try {
      final response = await _apiService.get('/favorites');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => FavoriteProduct.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }

  // Thêm sản phẩm vào yêu thích
  Future<FavoriteResult> addToFavorites(int productId) async {
    try {
      final response = await _apiService.post('/favorites', {'productId': productId});
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return FavoriteResult(success: true, message: 'Đã thêm vào yêu thích');
      } else if (response.statusCode == 409) {
        return FavoriteResult(success: false, message: 'Sản phẩm đã có trong danh sách yêu thích');
      } else if (response.statusCode == 404) {
        return FavoriteResult(success: false, message: 'Sản phẩm không tồn tại');
      } else {
        return FavoriteResult(success: false, message: 'Không thể thêm vào yêu thích');
      }
    } catch (e) {
      print('Error adding to favorites: $e');
      return FavoriteResult(success: false, message: 'Lỗi: $e');
    }
  }

  // Xóa sản phẩm khỏi yêu thích
  Future<FavoriteResult> removeFromFavorites(int productId) async {
    try {
      final response = await _apiService.delete('/favorites/$productId');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return FavoriteResult(success: true, message: 'Đã xóa khỏi yêu thích');
      } else {
        return FavoriteResult(success: false, message: 'Không thể xóa khỏi yêu thích');
      }
    } catch (e) {
      print('Error removing from favorites: $e');
      return FavoriteResult(success: false, message: 'Lỗi: $e');
    }
  }

  // Kiểm tra sản phẩm có trong yêu thích không
  Future<bool> isFavorite(int productId) async {
    final favorites = await getFavorites();
    return favorites.any((product) => product.id == productId);
  }
}

// Model cho sản phẩm yêu thích
class FavoriteProduct {
  final int id;
  final String name;
  final int price;
  final String? imageUrl;
  final String? description;
  final double rating;
  final CategoryInfo? category;
  final int? quantity;
  final bool? isSoldOut;

  FavoriteProduct({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.description,
    this.rating = 0,
    this.category,
    this.quantity,
    this.isSoldOut,
  });

  factory FavoriteProduct.fromJson(Map<String, dynamic> json) {
    return FavoriteProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      imageUrl: json['imageUrl'],
      description: json['description'],
      rating: (json['rating'] is int) 
          ? (json['rating'] as int).toDouble() 
          : (json['rating'] ?? 0.0),
      category: json['category'] != null 
          ? CategoryInfo.fromJson(json['category']) 
          : null,
      quantity: json['quantity'],
      isSoldOut: json['isSoldOut'],
    );
  }
}

class CategoryInfo {
  final int id;
  final String name;

  CategoryInfo({required this.id, required this.name});

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class FavoriteResult {
  final bool success;
  final String message;

  FavoriteResult({required this.success, required this.message});
}
