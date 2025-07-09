import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../../config/auth_config.dart';
import '../../../config/global_color.dart';
import '../../navbar/controller/navbar_controller.dart';
import '../../setting/controller/setting_controller.dart';
import 'token_manager.dart';
import 'user_profile_manager.dart';

class LoginController extends GetxController {
  var username = ''.obs;
  var password = ''.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var showPassword = false.obs;
  var isFaceIdEnabled = false.obs;
  var isLoginFrozen = false.obs;   // true: không cho nhập username, chỉ đăng nhập bằng user hiện tại
  var lastUsername = ''.obs;       // Username đã đăng nhập gần nhất (hoặc đang hiển thị trên form)
  final box = GetStorage();
  Timer? _refreshTimer;
  final NavbarController navbarController = Get.find<NavbarController>();

  String get _userKey => username.value.isNotEmpty ? username.value : (lastUsername.value.isNotEmpty ? lastUsername.value : (box.read('username') ?? ''));

  @override
  void onInit() {
    super.onInit();
    // Khi khởi động, xem có username đã lưu chưa
    lastUsername.value = box.read('username') ?? '';
    if (lastUsername.value.isNotEmpty) {
      username.value = lastUsername.value;
      isLoginFrozen.value = true;
    }
    TokenManager().loadTokens(box);
    UserProfileManager().loadProfile(box);
    loadFaceIdSetting();
    _startRefreshTimer();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  void setUsername(String value) {
    username.value = value;
    loadFaceIdSetting();
  }

  void setPassword(String value) => password.value = value;

  // Đăng nhập
  Future<void> login() async {
    if (username.value.isEmpty || password.value.isEmpty) {
      errorMessage.value = 'Vui lòng nhập đầy đủ username và password!';
      _showToast(errorMessage.value);
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';

    // DEMO chỉ chấp nhận admin/123
    if (username.value == 'admin' && password.value == '123') {
      await _onLoginSuccess();
      return;
    }

    // Thực hiện login thực tế của bạn tại đây (giữ nguyên như cũ)
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;

      HttpClientRequest request = await client.postUrl(
        Uri.parse('${AuthConfig.baseUrl}${AuthConfig.tokenEndpoint}'),
      );
      AuthConfig.getAuthHeaders().forEach((key, value) {
        request.headers.set(key, value);
      });
      Map<String, String> params = AuthConfig.getBaseParams('password');
      params['username'] = username.value;
      params['password'] = password.value;
      final query = Uri(queryParameters: params).query;
      request.write(query);
      HttpClientResponse response = await request.close();
      String responseBody = await response.transform(utf8.decoder).join();

      isLoading.value = false;

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        TokenManager().saveTokens(data, box);
        Map<String, dynamic> decodedToken = JwtDecoder.decode(
          TokenManager().civetToken.value,
        );
        bool isExpired = JwtDecoder.isExpired(TokenManager().civetToken.value);
        if (isExpired) {
          errorMessage.value = 'Token đã hết hạn!';
          _showToast(errorMessage.value);
          return;
        }
        UserProfileManager().updateProfile(decodedToken, username.value, box);
        await _onLoginSuccess();
      } else {
        errorMessage.value = 'Đăng nhập thất bại! Vui lòng kiểm tra lại thông tin. Mã lỗi: ${response.statusCode}';
        _showToast(errorMessage.value);
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Lỗi kết nối, vui lòng kiểm tra lại đường truyền!';
      _showToast(errorMessage.value);
    }
  }

  // Đăng nhập thành công: lưu local username, đóng băng username, reset pass, lưu mật khẩu quicklogin nếu đã bật
  Future<void> _onLoginSuccess() async {
    box.write('isLoggedIn', true);
    box.write('username', username.value);
    lastUsername.value = username.value;
    isLoginFrozen.value = true;
    // Nếu bật FaceID/vân tay, lưu luôn mật khẩu vào quicklogin cho user này
    if (isFaceIdEnabled.value) {
      saveQuickLoginPassword();
    }
    _startRefreshTimer();
    navbarController.currentIndex.value = 0;
    Get.offNamed('/navbar');
    isLoading.value = false;
    print('[Login] Đăng nhập thành công cho user: ${username.value}, FaceID: ${isFaceIdEnabled.value}');
  }

  // Đăng xuất: giữ lại username, đóng băng input, chỉ nhập lại mật khẩu, hiện nút đăng nhập bằng tài khoản khác
  void logout() async {
    final SettingController settingController = Get.find<SettingController>();
    final bool isDarkMode = settingController.isDarkMode.value;
    await _buildLogoutDialog(isDarkMode);
  }

  Future<void> _buildLogoutDialog(bool isDarkMode) async {
    await Get.defaultDialog(
      title: 'Xác nhận đăng xuất',
      middleText: 'Bạn có chắc chắn muốn đăng xuất?',
      titleStyle: TextStyle(
        color: isDarkMode ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      middleTextStyle: TextStyle(
        color: isDarkMode ? GlobalColors.darkSecondaryText : GlobalColors.lightSecondaryText,
        fontSize: 16,
      ),
      backgroundColor: isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      radius: 12,
      barrierDismissible: false,
      actions: [
        TextButton(
          onPressed: () async {
            await _performLogout();
            Get.back();
          },
          style: TextButton.styleFrom(
            backgroundColor: isDarkMode ? GlobalColors.primaryButtonDark : GlobalColors.primaryButtonLight,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Đăng xuất',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        TextButton(
          onPressed: () {
            Get.back();
          },
          style: TextButton.styleFrom(
            foregroundColor: isDarkMode ? GlobalColors.darkSecondaryText : GlobalColors.lightSecondaryText,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Hủy',
            style: TextStyle(
              color: isDarkMode ? GlobalColors.darkSecondaryText : GlobalColors.lightSecondaryText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Đăng nhập nhanh bằng FaceID/vân tay
  Future<void> quickLoginWithFaceId() async {
    final savedPassword = box.read('password_quick_login_$_userKey');
    if (isFaceIdEnabled.value && savedPassword != null && savedPassword.isNotEmpty) {
      password.value = savedPassword;
      await login();
    } else {
      Get.snackbar('Login', 'Bạn cần bật FaceID/vân tay ở Cài đặt để sử dụng!');
    }
  }

  // Bật/tắt FaceID cho user hiện tại
  void saveFaceIdSetting(bool value) {
    isFaceIdEnabled.value = value;
    box.write('isFaceIdEnabled_$_userKey', value);
    print('[saveFaceIdSetting] User: $_userKey, value: $value');
    if (value) {
      saveQuickLoginPassword();
    } else {
      box.remove('password_quick_login_$_userKey');
      print('[saveFaceIdSetting] Đã tắt FaceID và xóa mật khẩu quick login cho user này');
    }
  }

  // Lưu mật khẩu đăng nhập nhanh cho user
  void saveQuickLoginPassword() {
    if (_userKey.isNotEmpty && password.value.isNotEmpty) {
      box.write('password_quick_login_$_userKey', password.value);
      print('[saveQuickLoginPassword] User: $_userKey, Đã lưu mật khẩu quick login');
    }
  }

  // Load trạng thái bật FaceID cho user hiện tại
  void loadFaceIdSetting() {
    isFaceIdEnabled.value = box.read('isFaceIdEnabled_$_userKey') ?? false;
    print('[loadFaceIdSetting] User: $_userKey, enabled: ${isFaceIdEnabled.value}');
  }

  // Reset tất cả info để cho phép đăng nhập tài khoản khác
  void resetAllForNewUser() {
    print('[resetAllForNewUser] Clear all for new user');
    if (_userKey.isNotEmpty) {
      box.remove('isFaceIdEnabled_$_userKey');
      box.remove('password_quick_login_$_userKey');
    }
    box.write('username', '');
    box.write('isLoggedIn', false);
    username.value = '';
    password.value = '';
    lastUsername.value = '';
    isFaceIdEnabled.value = false;
    isLoginFrozen.value = false;
    errorMessage.value = '';
  }

  // Future<void> _performLogout() async {
  //   _refreshTimer?.cancel();
  //   box.write('isLoggedIn', false);
  //   // Giữ lại username đã login gần nhất để hiển thị, không xóa quick login/faceid
  //   TokenManager().clearTokens(box);
  //   UserProfileManager().clearProfile(box);
  //   password.value = '';
  //   errorMessage.value = '';
  //   isLoginFrozen.value = true;
  //   username.value = lastUsername.value;
  //   final selectedLanguage = box.read('selectedLanguage') ?? 'en';
  //   Get.updateLocale(Locale(selectedLanguage));
  //   await Get.offAllNamed('/login');
  //   print('[logout] User: $username');
  // }
  Future<void> _performLogout() async {
    _refreshTimer?.cancel();
    box.write('isLoggedIn', false);
    // box.write('username', '');
    // TokenManager().clearTokens(box);
    // UserProfileManager().clearProfile(box);
    // username.value = '';
    // password.value = '';
    // errorMessage.value = '';
    // final selectedLanguage = box.read('selectedLanguage') ?? 'en';
    // Get.updateLocale(Locale(selectedLanguage));
    await Get.offAllNamed('/login');
  }

  void _showToast(String message, {Color? backgroundColor}) {
    final bool isDarkMode = Get.find<SettingController>().isDarkMode.value;
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor ?? (isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg),
      textColor: isDarkMode ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText,
      fontSize: 16.0,
      timeInSecForIosWeb: 3,
    );
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    if (TokenManager().civetToken.value.isNotEmpty) {
      int refreshTime = TokenManager().getRefreshTime();
      if (refreshTime > 0) {
        _refreshTimer = Timer(Duration(seconds: refreshTime), () {
          TokenManager().refreshAccessToken(box, logout);
        });
      }
    }
  }

  // Đăng nhập bằng tài khoản khác (xóa hết local và UI reset)
  void clearUserForNewLogin() {
    resetAllForNewUser();
    update();
  }
}
