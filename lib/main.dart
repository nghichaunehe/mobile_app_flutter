import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_screen.dart'; // Màn hình Đăng nhập/Đăng ký
import 'home_screen.dart'; // Màn hình Trang chủ
import 'cart_screen.dart'; // Màn hình Giỏ hàng
import 'checkout_screen.dart'; // Màn hình Thanh toán
import 'product_detail_screen.dart'; // Màn hình Chi tiết sản phẩm
import 'confirmation_screen.dart'; // Màn hình Xác nhận đơn hàng
import 'user_profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColorValue = Color(0xFF4C4D78); // Màu chủ đạo giả định

    // FIX: Định nghĩa đầy đủ tất cả 10 shade màu (50-900) cho MaterialColor
    MaterialColor createMaterialColor(Color color) {
      List strengths = <double>[.05];
      Map<int, Color> swatch = {};
      final int r = color.red, g = color.green, b = color.blue;

      for (int i = 1; i < 10; i++) {
        strengths.add(0.1 * i);
      }
      for (var strength in strengths) {
        final double ds = 0.5 - strength;
        swatch[(strength * 1000).round()] = Color.fromRGBO(
          r + ((ds < 0 ? r : (255 - r)) * ds).round(),
          g + ((ds < 0 ? g : (255 - g)) * ds).round(),
          b + ((ds < 0 ? b : (255 - b)) * ds).round(),
          1,
        );
      }

      swatch[500] = color;
      
      return MaterialColor(color.value, swatch);
    }

    final customPrimarySwatch = createMaterialColor(primaryColorValue);

    return MaterialApp(
      title: 'Auth App UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: customPrimarySwatch,
          accentColor: primaryColorValue,
        ).copyWith(secondary: primaryColorValue),
        scaffoldBackgroundColor: const Color(0xFFF5F7F8),
      ),

      initialRoute: '/',
      routes: {
        '/': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const AuthScreen(),
        '/profile': (context) => const UserProfileScreen(),
        
        '/cart': (context) => const CartScreen(),
        '/detail': (context) => const ProductDetailScreen(),
        '/checkout': (context) => const CheckoutScreen(),
      },
    );
  }
}