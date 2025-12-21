# Mobile App Flutter

## Yêu cầu hệ thống

- Flutter SDK
- Android Studio
- Dart SDK

## Hướng dẫn cài đặt và chạy ứng dụng

### 1. Tải và cài đặt Android Studio

- Tải Android Studio từ: https://developer.android.com/studio
- Cài đặt Android Studio và các component cần thiết
- Cài đặt Android SDK và Android Emulator thông qua SDK Manager

### 2. Cài đặt Flutter SDK

- Tải Flutter SDK từ: https://flutter.dev/docs/get-started/install
- Giải nén và thêm Flutter vào PATH
- Chạy `flutter doctor` để kiểm tra cài đặt

### 3. Cài đặt dependencies

```bash
flutter pub get
```

### 4. Khởi chạy emulator

```bash
flutter emulators --launch Medium_Phone_API_36.1
```

### 5. Chạy ứng dụng

```bash
flutter run -d emulator-5554
```

## Các lệnh hữu ích khác

- Xem danh sách emulator: `flutter emulators`
- Xem danh sách thiết bị đang kết nối: `flutter devices`
- Build APK: `flutter build apk`
- Chạy ở chế độ release: `flutter run --release`

## Cấu trúc dự án

- `lib/` - Mã nguồn chính của ứng dụng
- `android/` - Cấu hình Android native
- `ios/` - Cấu hình iOS native
- `assets/` - Tài nguyên như fonts, hình ảnh
- `test/` - Unit tests và widget tests
