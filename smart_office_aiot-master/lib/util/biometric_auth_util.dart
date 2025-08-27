import 'package:local_auth/local_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';

class BiometricAuthUtil {
  static final LocalAuthentication _auth = LocalAuthentication();
  static final box = GetStorage();

  /// Kiểm tra thiết bị hỗ trợ FaceID/vân tay và đã bật
  static Future<bool> hasBiometricSupport() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      debugPrint('[Biometric] canCheckBiometrics: $canCheck, isDeviceSupported: $isDeviceSupported');
      return canCheck && isDeviceSupported;
    } catch (e) {
      debugPrint('[Biometric] Error checking biometrics: $e');
      return false;
    }
  }

  /// Xác thực sinh trắc học (hiện popup FaceID/vân tay)
  static Future<bool> authenticate({String? reason}) async {
    try {
      final bool didAuth = await _auth.authenticate(
        localizedReason: reason ?? "Xác thực bằng vân tay hoặc khuôn mặt để đăng nhập",
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      debugPrint('[Biometric] Authenticate: $didAuth');
      return didAuth;
    } catch (e) {
      debugPrint('[Biometric] Authenticate error: $e');
      return false;
    }
  }

  /// Lưu mật khẩu quick login cho user (gọi sau khi đăng nhập thành công)
  static void saveQuickLoginInfo(String username, String password) {
    if (username.isNotEmpty && password.isNotEmpty) {
      box.write('biometric_username', username);
      box.write('biometric_password', password);
      box.write('biometric_enabled', true);
      debugPrint('[Biometric] Saved quick login info for $username');
    }
  }

  /// Xóa mật khẩu quick login (gọi khi logout hoặc tắt FaceID/vân tay trong setting)
  static void clearQuickLoginInfo() {
    box.remove('biometric_username');
    box.remove('biometric_password');
    box.write('biometric_enabled', false);
    debugPrint('[Biometric] Cleared quick login info');
  }

  /// Kiểm tra đã lưu quick login info chưa (đã enable trong setting chưa)
  static bool isQuickLoginAvailable() {
    final enabled = box.read('biometric_enabled') ?? false;
    final username = box.read('biometric_username');
    final password = box.read('biometric_password');
    debugPrint('[Biometric] Quick login enabled: $enabled, username: $username');
    return enabled && username != null && password != null && username.isNotEmpty && password.isNotEmpty;
  }

  /// Lấy lại thông tin đăng nhập (user/pass) đã lưu để truyền về controller login
  static Map<String, String>? getQuickLoginInfo() {
    if (!isQuickLoginAvailable()) return null;
    final username = box.read('biometric_username');
    final password = box.read('biometric_password');
    return {'username': username, 'password': password};
  }
}
