import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/api_service.dart';
import 'secure_storage_manager.dart';
import 'orders_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Cấu hình màu sắc và font chữ tương tự Tailwind config
        scaffoldBackgroundColor: const Color(0xFFF5F7F8), // bg-background-light
        primaryColor: const Color(0xFF0D7FF2), // primary
        fontFamily: 'Roboto', // Hoặc 'Plus Jakarta Sans' nếu bạn đã thêm font
        useMaterial3: true,
      ),
      home: const UserProfileScreen(),
    );
  }
}

class UserProfile {
  final String fullName;
  final String email;

  UserProfile({required this.fullName, required this.email});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
    );
  }

  UserProfile copyWith({String? fullName, String? email}) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
    );
  }
}

class ShippingAddress {
  final String id;
  final String address;
  final String recipientName;
  final String phone;
  final bool isDefault;

  ShippingAddress({
    required this.id,
    required this.address,
    required this.recipientName,
    required this.phone,
    required this.isDefault,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      id: json['id']?.toString() ?? '',
      address: json['address'] ?? '',
      recipientName: json['recipientName'] ?? '',
      phone: json['phone'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }
}

class _Province {
  final String code;
  final String name;

  _Province({required this.code, required this.name});

  factory _Province.fromJson(Map<String, dynamic> json) {
    return _Province(
      code: json['code']?.toString() ?? '',
      name: json['name'] ?? '',
    );
  }
}

class _District {
  final String code;
  final String name;

  _District({required this.code, required this.name});

  factory _District.fromJson(Map<String, dynamic> json) {
    return _District(
      code: json['code']?.toString() ?? '',
      name: json['name'] ?? '',
    );
  }
}

class _Ward {
  final String code;
  final String name;

  _Ward({required this.code, required this.name});

  factory _Ward.fromJson(Map<String, dynamic> json) {
    return _Ward(
      code: json['code']?.toString() ?? '',
      name: json['name'] ?? '',
    );
  }
}

Future<void> _handleLogout(BuildContext context) async {
  // Hiện hộp thoại xác nhận
  final bool shouldLogout = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Đăng xuất"),
      content: const Text("Bạn có chắc chắn muốn đăng xuất?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Hủy"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("Đồng ý", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  ) ?? false;

  if (shouldLogout) {
    // Xóa JWT khỏi bộ nhớ an toàn
    await SecureStorageManager.deleteJwt();

    // Chuyển về màn hình Login và xóa hết lịch sử cũ
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }
}

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _addressSectionKey = GlobalKey();

  UserProfile? _profile;
  List<ShippingAddress> _addresses = [];
  bool _isLoading = true;
  bool _isSavingName = false;
  bool _isSavingAddress = false;
  List<_Province> _provinces = [];
  List<_District> _districts = [];
  List<_Ward> _wards = [];
  bool _isLoadingProvinces = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingWards = false;
  String? _provinceError;
  String? _districtError;
  String? _wardError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _fetchProfile(),
      _fetchAddresses(),
    ]);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await _apiService.get('/user/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _profile = UserProfile.fromJson(data);
        });
      } else if (response.statusCode == 401 && mounted) {
        await _handleLogout(context);
      } else {
        _showSnack('Không tải được thông tin người dùng');
      }
    } catch (e) {
      _showSnack('Lỗi tải hồ sơ: $e');
    }
  }

  Future<void> _fetchAddresses() async {
    try {
      final response = await _apiService.get('/user/me/addresses');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _addresses = data.map((e) => ShippingAddress.fromJson(e)).toList();
        });
      } else if (response.statusCode == 401 && mounted) {
        await _handleLogout(context);
      } else {
        _showSnack('Không tải được danh sách địa chỉ');
      }
    } catch (e) {
      _showSnack('Lỗi tải địa chỉ: $e');
    }
  }

  Future<void> _ensureProvinces() async {
    if (_provinces.isNotEmpty || _isLoadingProvinces) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingProvinces = true;
        _provinceError = null;
      });
    }

    try {
      final response = await http.get(Uri.parse('https://provinces.open-api.vn/api/p/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final provinces = data
            .map((e) => _Province.fromJson(e))
            .where((province) => province.name.isNotEmpty)
            .toList();

        if (mounted) {
          setState(() {
            _provinces = provinces;
            _provinceError = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _provinceError = 'Không tải được danh sách tỉnh thành';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _provinceError = 'Lỗi tải tỉnh thành: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProvinces = false;
        });
      }
    }
  }

  String _normalizeText(String value) => value.toLowerCase().trim();

  bool _matchesName(String source, String target) {
    if (source.isEmpty || target.isEmpty) {
      return false;
    }
    final normalizedSource = _normalizeText(source);
    final normalizedTarget = _normalizeText(target);
    return normalizedSource == normalizedTarget ||
        normalizedSource.contains(normalizedTarget) ||
        normalizedTarget.contains(normalizedSource);
  }

  _Province? _findProvinceByName(String name) {
    for (final province in _provinces) {
      if (_matchesName(province.name, name)) {
        return province;
      }
    }
    return null;
  }

  _District? _findDistrictByName(String name) {
    for (final district in _districts) {
      if (_matchesName(district.name, name)) {
        return district;
      }
    }
    return null;
  }

  _Ward? _findWardByName(String name) {
    for (final ward in _wards) {
      if (_matchesName(ward.name, name)) {
        return ward;
      }
    }
    return null;
  }

  Future<void> _loadDistrictsForProvince(String provinceCode) async {
    if (provinceCode.isEmpty) {
      if (mounted) {
        setState(() {
          _districts = [];
          _districtError = null;
          _isLoadingDistricts = false;
          _wards = [];
          _wardError = null;
          _isLoadingWards = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingDistricts = true;
        _districtError = null;
        _districts = [];
        _wards = [];
        _wardError = null;
        _isLoadingWards = false;
      });
    }

    try {
      final response = await http.get(Uri.parse('https://provinces.open-api.vn/api/p/$provinceCode?depth=2'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final districtData = data['districts'] as List<dynamic>? ?? [];
        final parsed = districtData
            .map((e) => _District.fromJson(e as Map<String, dynamic>))
            .where((district) => district.name.isNotEmpty)
            .toList();

        if (mounted) {
          setState(() {
            _districts = parsed;
            _districtError = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _districtError = 'Không tải được quận huyện';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _districtError = 'Lỗi tải quận huyện: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDistricts = false;
        });
      }
    }
  }

  Future<void> _loadWardsForDistrict(String districtCode) async {
    if (districtCode.isEmpty) {
      if (mounted) {
        setState(() {
          _wards = [];
          _wardError = null;
          _isLoadingWards = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingWards = true;
        _wardError = null;
        _wards = [];
      });
    }

    try {
      final response = await http.get(Uri.parse('https://provinces.open-api.vn/api/d/$districtCode?depth=2'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final wardData = data['wards'] as List<dynamic>? ?? [];
        final parsed = wardData
            .map((e) => _Ward.fromJson(e as Map<String, dynamic>))
            .where((ward) => ward.name.isNotEmpty)
            .toList();

        if (mounted) {
          setState(() {
            _wards = parsed;
            _wardError = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _wardError = 'Không tải được phường xã';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _wardError = 'Lỗi tải phường xã: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWards = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _updateFullName(String newName) async {
    setState(() {
      _isSavingName = true;
    });

    try {
      final response = await _apiService.patch('/user/me', {'fullName': newName});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _profile = _profile?.copyWith(fullName: data['fullName'] ?? newName, email: data['email']);
        });
        _showSnack('Đã cập nhật tên');
      } else if (response.statusCode == 401 && mounted) {
        await _handleLogout(context);
      } else {
        _showSnack('Không cập nhật được tên');
      }
    } catch (e) {
      _showSnack('Lỗi cập nhật tên: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingName = false;
        });
      }
    }
  }

  Future<void> _submitAddress({ShippingAddress? current, required String address, required String recipient, required String phone, required bool isDefault}) async {
    setState(() {
      _isSavingAddress = true;
    });

    try {
      final body = {
        'address': address,
        'recipientName': recipient.isNotEmpty ? recipient : null,
        'phone': phone.isNotEmpty ? phone : null,
        'isDefault': isDefault,
      }..removeWhere((key, value) => value == null);

      late final http.Response response;
      if (current == null) {
        response = await _apiService.post('/user/me/addresses', body);
      } else {
        response = await _apiService.patch('/user/me/addresses/${current.id}', body);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _fetchAddresses();
        _showSnack(current == null ? 'Đã thêm địa chỉ' : 'Đã cập nhật địa chỉ');
      } else if (response.statusCode == 401 && mounted) {
        await _handleLogout(context);
      } else {
        _showSnack('Không lưu được địa chỉ');
      }
    } catch (e) {
      _showSnack('Lỗi lưu địa chỉ: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingAddress = false;
        });
      }
    }
  }

  Future<void> _setDefaultAddress(String id) async {
    setState(() {
      _isSavingAddress = true;
    });
    try {
      final response = await _apiService.patch('/user/me/addresses/$id', {'isDefault': true});
      if (response.statusCode == 200 || response.statusCode == 201) {
        await _fetchAddresses();
      } else if (response.statusCode == 401 && mounted) {
        await _handleLogout(context);
      } else {
        _showSnack('Không đặt mặc định được địa chỉ');
      }
    } catch (e) {
      _showSnack('Lỗi đặt mặc định: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingAddress = false;
        });
      }
    }
  }

  Future<void> _deleteAddress(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa địa chỉ'),
        content: const Text('Bạn chắc chắn muốn xóa địa chỉ này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSavingAddress = true;
    });
    try {
      final response = await _apiService.delete('/user/me/addresses/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        await _fetchAddresses();
        _showSnack('Đã xóa địa chỉ');
      } else if (response.statusCode == 401 && mounted) {
        await _handleLogout(context);
      } else {
        _showSnack('Không xóa được địa chỉ');
      }
    } catch (e) {
      _showSnack('Lỗi xóa địa chỉ: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingAddress = false;
        });
      }
    }
  }

  void _openEditNameSheet() {
    final controller = TextEditingController(text: _profile?.fullName ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cập nhật tên hiển thị', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSavingName
                      ? null
                      : () async {
                          final name = controller.text.trim();
                          if (name.isEmpty) {
                            _showSnack('Tên không được để trống');
                            return;
                          }
                          Navigator.pop(ctx);
                          await _updateFullName(name);
                        },
                  child: _isSavingName
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Lưu'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAddressForm({ShippingAddress? current}) async {
    await _ensureProvinces();
    if (!mounted) {
      return;
    }

    final originalAddress = current?.address ?? '';
    final remainingSegments = originalAddress.isNotEmpty
        ? originalAddress
            .split(',')
            .map((segment) => segment.trim())
            .where((segment) => segment.isNotEmpty)
            .toList()
        : <String>[];

    String initialDetail = '';
    String initialProvince = '';
    String initialDistrict = '';
    String initialWard = '';
    String selectedProvinceCode = '';
    String selectedDistrictCode = '';
    String selectedWardCode = '';

    bool provinceFound = false;
    for (int i = remainingSegments.length - 1; i >= 0; i--) {
      final candidate = remainingSegments[i];
      final match = _findProvinceByName(candidate);
      if (match != null) {
        initialProvince = candidate;
        selectedProvinceCode = match.code;
        remainingSegments.removeAt(i);
        provinceFound = true;
        await _loadDistrictsForProvince(selectedProvinceCode);
        if (!mounted) {
          return;
        }
        break;
      }
    }
    if (!provinceFound) {
      await _loadDistrictsForProvince('');
      if (!mounted) {
        return;
      }
    }

    bool districtFound = false;
    if (selectedProvinceCode.isNotEmpty) {
      for (int i = remainingSegments.length - 1; i >= 0; i--) {
        final candidate = remainingSegments[i];
        final match = _findDistrictByName(candidate);
        if (match != null) {
          initialDistrict = candidate;
          selectedDistrictCode = match.code;
          remainingSegments.removeAt(i);
          districtFound = true;
          await _loadWardsForDistrict(selectedDistrictCode);
          if (!mounted) {
            return;
          }
          break;
        }
      }
    }
    if (!districtFound) {
      await _loadWardsForDistrict('');
      if (!mounted) {
        return;
      }
    }

    if (selectedDistrictCode.isNotEmpty) {
      for (int i = remainingSegments.length - 1; i >= 0; i--) {
        final candidate = remainingSegments[i];
        final match = _findWardByName(candidate);
        if (match != null) {
          initialWard = candidate;
          selectedWardCode = match.code;
          remainingSegments.removeAt(i);
          break;
        }
      }
    }

    if (remainingSegments.isNotEmpty) {
      initialDetail = remainingSegments.join(', ');
    }
    if (initialDetail.isEmpty && originalAddress.isNotEmpty && !provinceFound && !districtFound && initialWard.isEmpty) {
      initialDetail = originalAddress;
    }

    final detailController = TextEditingController(text: initialDetail);
    final wardController = TextEditingController(text: initialWard);
    final districtController = TextEditingController(text: initialDistrict);
    final provinceController = TextEditingController(text: initialProvince);
    final recipientController = TextEditingController(text: current?.recipientName ?? '');
    final phoneController = TextEditingController(text: current?.phone ?? '');
    bool isDefault = current?.isDefault ?? false;

    List<_Province> provinceSuggestions = [];
    List<_District> districtSuggestions = [];
    List<_Ward> wardSuggestions = [];

    List<_Province> filterProvinceSuggestions(String value) {
      final query = _normalizeText(value);
      if (query.length < 2) {
        return [];
      }
      return _provinces
          .where((province) => _normalizeText(province.name).contains(query))
          .take(8)
          .toList();
    }

    List<_District> filterDistrictSuggestions(String value) {
      final query = _normalizeText(value);
      if (query.isEmpty) {
        return _districts.take(8).toList();
      }
      return _districts
          .where((district) => _normalizeText(district.name).contains(query))
          .take(8)
          .toList();
    }

    List<_Ward> filterWardSuggestions(String value) {
      final query = _normalizeText(value);
      if (query.isEmpty) {
        return _wards.take(8).toList();
      }
      return _wards
          .where((ward) => _normalizeText(ward.name).contains(query))
          .take(8)
          .toList();
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            void handleProvinceChange(String value) {
              if (selectedProvinceCode.isNotEmpty) {
                _Province? currentProvince;
                for (final province in _provinces) {
                  if (province.code == selectedProvinceCode) {
                    currentProvince = province;
                    break;
                  }
                }
                if (currentProvince == null || !_matchesName(currentProvince.name, value)) {
                  selectedProvinceCode = '';
                  selectedDistrictCode = '';
                  selectedWardCode = '';
                  districtController.clear();
                  wardController.clear();
                  setState(() {
                    _districts = [];
                    _districtError = null;
                    _isLoadingDistricts = false;
                    _wards = [];
                    _wardError = null;
                    _isLoadingWards = false;
                  });
                }
              }

              setModalState(() {
                provinceSuggestions = filterProvinceSuggestions(value);
                districtSuggestions = [];
                wardSuggestions = [];
              });
            }

            void handleDistrictChange(String value) {
              if (selectedDistrictCode.isNotEmpty) {
                _District? currentDistrict;
                for (final district in _districts) {
                  if (district.code == selectedDistrictCode) {
                    currentDistrict = district;
                    break;
                  }
                }
                if (currentDistrict == null || !_matchesName(currentDistrict.name, value)) {
                  selectedDistrictCode = '';
                  selectedWardCode = '';
                  wardController.clear();
                  setState(() {
                    _wards = [];
                    _wardError = null;
                    _isLoadingWards = false;
                  });
                }
              }

              setModalState(() {
                districtSuggestions = filterDistrictSuggestions(value);
                wardSuggestions = [];
              });
            }

            void handleWardChange(String value) {
              if (selectedWardCode.isNotEmpty) {
                _Ward? currentWard;
                for (final ward in _wards) {
                  if (ward.code == selectedWardCode) {
                    currentWard = ward;
                    break;
                  }
                }
                if (currentWard == null || !_matchesName(currentWard.name, value)) {
                  selectedWardCode = '';
                }
              }

              setModalState(() {
                wardSuggestions = filterWardSuggestions(value);
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(current == null ? 'Thêm địa chỉ' : 'Cập nhật địa chỉ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: provinceController,
                    decoration: const InputDecoration(
                      labelText: 'Tỉnh/Thành phố',
                      hintText: 'Nhập tên tỉnh thành...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: handleProvinceChange,
                  ),
                  if (_isLoadingProvinces)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  else if (_provinceError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _provinceError!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    )
                  else if (provinceSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: provinceSuggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        itemBuilder: (context, index) {
                          final province = provinceSuggestions[index];
                          return ListTile(
                            dense: true,
                            title: Text(province.name, style: const TextStyle(fontSize: 14)),
                            onTap: () async {
                              provinceController.text = province.name;
                              provinceController.selection = TextSelection.fromPosition(
                                TextPosition(offset: province.name.length),
                              );
                              selectedProvinceCode = province.code;
                              selectedDistrictCode = '';
                              selectedWardCode = '';
                              districtController.clear();
                              wardController.clear();
                              setModalState(() {
                                provinceSuggestions = [];
                                districtSuggestions = [];
                                wardSuggestions = [];
                              });
                              await _loadDistrictsForProvince(province.code);
                              if (!mounted || !ctx.mounted) {
                                return;
                              }
                              setModalState(() {
                                districtSuggestions = filterDistrictSuggestions(districtController.text);
                              });
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: districtController,
                    enabled: selectedProvinceCode.isNotEmpty || _districts.isNotEmpty,
                    decoration: const InputDecoration(
                      labelText: 'Quận/Huyện',
                      hintText: 'Nhập tên quận huyện...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: handleDistrictChange,
                  ),
                  if (selectedProvinceCode.isEmpty && _districts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Vui lòng chọn tỉnh/thành trước.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    )
                  else if (_isLoadingDistricts)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  else if (_districtError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _districtError!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    )
                  else if (districtSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: districtSuggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        itemBuilder: (context, index) {
                          final district = districtSuggestions[index];
                          return ListTile(
                            dense: true,
                            title: Text(district.name, style: const TextStyle(fontSize: 14)),
                            onTap: () async {
                              districtController.text = district.name;
                              districtController.selection = TextSelection.fromPosition(
                                TextPosition(offset: district.name.length),
                              );
                              selectedDistrictCode = district.code;
                              selectedWardCode = '';
                              wardController.clear();
                              setModalState(() {
                                districtSuggestions = [];
                                wardSuggestions = [];
                              });
                              await _loadWardsForDistrict(district.code);
                              if (!mounted || !ctx.mounted) {
                                return;
                              }
                              setModalState(() {
                                wardSuggestions = filterWardSuggestions(wardController.text);
                              });
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: wardController,
                    enabled: selectedDistrictCode.isNotEmpty || _wards.isNotEmpty,
                    decoration: const InputDecoration(
                      labelText: 'Phường/Xã',
                      hintText: 'Nhập tên phường xã...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: handleWardChange,
                  ),
                  if (selectedDistrictCode.isEmpty && _wards.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Vui lòng chọn quận/huyện trước.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    )
                  else if (_isLoadingWards)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  else if (_wardError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _wardError!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    )
                  else if (wardSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: wardSuggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        itemBuilder: (context, index) {
                          final ward = wardSuggestions[index];
                          return ListTile(
                            dense: true,
                            title: Text(ward.name, style: const TextStyle(fontSize: 14)),
                            onTap: () {
                              wardController.text = ward.name;
                              wardController.selection = TextSelection.fromPosition(
                                TextPosition(offset: ward.name.length),
                              );
                              selectedWardCode = ward.code;
                              setModalState(() {
                                wardSuggestions = [];
                              });
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ chi tiết',
                      hintText: 'Số nhà, đường, khu vực cụ thể',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: recipientController,
                    decoration: const InputDecoration(labelText: 'Tên người nhận (tùy chọn)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Số điện thoại (tùy chọn)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: isDefault,
                    onChanged: (val) {
                      setModalState(() {
                        isDefault = val ?? false;
                      });
                    },
                    title: const Text('Đặt làm địa chỉ mặc định'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSavingAddress
                          ? null
                          : () async {
                              final detail = detailController.text.trim();
                              final ward = wardController.text.trim();
                              final district = districtController.text.trim();
                              final province = provinceController.text.trim();

                              if (detail.isEmpty && ward.isEmpty && district.isEmpty && province.isEmpty) {
                                _showSnack('Địa chỉ không được để trống');
                                return;
                              }

                              final composedAddress = [detail, ward, district, province]
                                  .where((part) => part.isNotEmpty)
                                  .join(', ');

                              Navigator.pop(ctx);
                              await _submitAddress(
                                current: current,
                                address: composedAddress,
                                recipient: recipientController.text.trim(),
                                phone: phoneController.text.trim(),
                                isDefault: isDefault,
                              );
                            },
                      child: _isSavingAddress
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Lưu địa chỉ'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    detailController.dispose();
    wardController.dispose();
    districtController.dispose();
    provinceController.dispose();
    recipientController.dispose();
    phoneController.dispose();
  }

  void _scrollToAddresses() {
    final ctx = _addressSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D7FF2);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Hồ sơ người dùng",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage('https://lh3.googleusercontent.com/a/default-user=s96-c'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _profile?.fullName.isNotEmpty == true ? _profile!.fullName : 'Chưa có tên',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _profile?.email.isNotEmpty == true ? _profile!.email : 'Chưa có email',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _openEditNameSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor.withOpacity(0.1),
                            foregroundColor: primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Chỉnh sửa tên",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              icon: Icons.local_mall_outlined,
                              text: "Đơn hàng của tôi",
                              iconColor: primaryColor,
                              iconBgColor: primaryColor.withOpacity(0.1),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const OrdersScreen()),
                                );
                              },
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.location_on_outlined,
                              text: "Địa chỉ đã lưu",
                              iconColor: primaryColor,
                              iconBgColor: primaryColor.withOpacity(0.1),
                              onTap: _scrollToAddresses,
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.payment_outlined,
                              text: "Phương thức thanh toán",
                              iconColor: primaryColor,
                              iconBgColor: primaryColor.withOpacity(0.1),
                              isLast: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildAddressSection(primaryColor),

                      const SizedBox(height: 24),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              icon: Icons.settings_outlined,
                              text: "Cài đặt",
                              iconColor: Colors.black54,
                              iconBgColor: Colors.grey.shade200,
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.lock_outline,
                              text: "Thay đổi mật khẩu",
                              iconColor: primaryColor,
                              iconBgColor: primaryColor.withOpacity(0.1),
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.logout,
                              text: "Đăng xuất",
                              textColor: Colors.red,
                              iconColor: Colors.black54,
                              iconBgColor: Colors.grey.shade200,
                              showChevron: false,
                              isLast: true,
                              onTap: () => _handleLogout(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAddressSection(Color primaryColor) {
    return Container(
      key: _addressSectionKey,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Địa chỉ giao hàng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _isSavingAddress ? null : () => _openAddressForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isSavingAddress)
            const LinearProgressIndicator(minHeight: 2),
          if (_addresses.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Chưa có địa chỉ. Thêm mới ngay.'),
            )
          else
            Column(
              children: _addresses.map((addr) {
                return Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: addr.isDefault ? primaryColor : const Color(0xFFE2E8F0)),
                    color: addr.isDefault ? primaryColor.withOpacity(0.04) : Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(addr.address, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                if (addr.recipientName.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('Người nhận: ${addr.recipientName}'),
                                  ),
                                if (addr.phone.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text('SĐT: ${addr.phone}'),
                                  ),
                              ],
                            ),
                          ),
                          if (addr.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Mặc định', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (!addr.isDefault)
                            TextButton(
                              onPressed: _isSavingAddress ? null : () => _setDefaultAddress(addr.id),
                              child: const Text('Đặt mặc định'),
                            ),
                          TextButton(
                            onPressed: _isSavingAddress ? null : () => _openAddressForm(current: addr),
                            child: const Text('Sửa'),
                          ),
                          TextButton(
                            onPressed: _isSavingAddress ? null : () => _deleteAddress(addr.id),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: Color(0xFFE2E8F0));
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required Color iconColor,
    required Color iconBgColor,
    Color textColor = const Color(0xFF1E293B),
    bool showChevron = true,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(12)) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (showChevron)
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF94A3B8),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}