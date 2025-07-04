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
  var showPassword = false.obs; // Hiển thị mật khẩu khi nhấn giữ
  final box = GetStorage();
  Timer? _refreshTimer;
  final NavbarController navbarController = Get.find<NavbarController>();

  @override
  void onInit() {
    super.onInit();
    username.value = box.read('username') ?? '';
    TokenManager().loadTokens(box);
    UserProfileManager().loadProfile(box);
    _startRefreshTimer();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  void setUsername(String value) => username.value = value;

  void setPassword(String value) => password.value = value;

  Future<void> login() async {
    if (username.value.isEmpty || password.value.isEmpty) {
      errorMessage.value = 'Vui lòng nhập đầy đủ username và password!';
      _showToast(errorMessage.value);
      return;
    }
    // Hardcoded admin account check
    if (username.value == 'admin' && password.value == '123') {
      isLoading.value = true;
      errorMessage.value = '';
      box.write('isLoggedIn', true);
      box.write('username', username.value);
      navbarController.currentIndex.value = 0;
      Get.offNamed('/navbar');
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

      HttpClientRequest request = await client.postUrl(
        Uri.parse('${AuthConfig.baseUrl}${AuthConfig.tokenEndpoint}'),
      );
      AuthConfig.getAuthHeaders().forEach((key, value) {
        request.headers.set(key, value);
      });
      Map<String, String> params = AuthConfig.getBaseParams('password');
      params['username'] = username.value;
      params['password'] = password.value;
      request.write(params.entries.map((e) => '${e.key}=${e.value}').join('&'));
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
        box.write('isLoggedIn', true);
        box.write('username', username.value);
        _startRefreshTimer();
        navbarController.currentIndex.value = 0; // Chuyển về tab Home
        Get.offNamed('/navbar');
      } else {
        errorMessage.value =
            'Đăng nhập thất bại! Vui lòng kiểm tra lại thông tin. Mã lỗi: ${response.statusCode}';
        _showToast(errorMessage.value);
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Lỗi kết nối, vui lòng kiểm tra lại đường truyền!';
      _showToast(errorMessage.value);
    }
  }

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
        color: isDarkMode
            ? GlobalColors.darkPrimaryText
            : GlobalColors.lightPrimaryText,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      middleTextStyle: TextStyle(
        color: isDarkMode
            ? GlobalColors.darkSecondaryText
            : GlobalColors.lightSecondaryText,
        fontSize: 16,
      ),
      backgroundColor:
      isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      radius: 12,
      barrierDismissible: false,
      actions: [
        TextButton(
          onPressed: () async {
            await _performLogout();
            Get.back(); // Đóng dialog sau khi đăng xuất
          },
          style: TextButton.styleFrom(
            backgroundColor: isDarkMode
                ? GlobalColors.primaryButtonDark
                : GlobalColors.primaryButtonLight,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Đăng xuất',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Get.back(); // Đóng dialog
          },
          style: TextButton.styleFrom(
            foregroundColor: isDarkMode
                ? GlobalColors.darkSecondaryText
                : GlobalColors.lightSecondaryText,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Hủy',
            style: TextStyle(
              color: isDarkMode
                  ? GlobalColors.darkSecondaryText
                  : GlobalColors.lightSecondaryText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }


  Future<void> _performLogout() async {
    _refreshTimer?.cancel();
    box.write('isLoggedIn', false);
    box.write('username', '');
    TokenManager().clearTokens(box);
    UserProfileManager().clearProfile(box);
    username.value = '';
    password.value = '';
    errorMessage.value = '';
    final selectedLanguage = box.read('selectedLanguage') ?? 'en';
    Get.updateLocale(Locale(selectedLanguage));
    await Get.offAllNamed('/login');
  }

  void _showToast(String message, {Color? backgroundColor}) {
    final bool isDarkMode = Get.find<SettingController>().isDarkMode.value;
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor ??
          (isDarkMode
              ? GlobalColors.cardDarkBg
              : GlobalColors.cardLightBg),
      textColor: isDarkMode
          ? GlobalColors.darkPrimaryText
          : GlobalColors.lightPrimaryText,
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
}
