import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../model/version_check_summary.dart';
import '../../../service/update_service.dart';

class SettingController extends GetxController {
  var isDarkMode = false.obs;
  final box = GetStorage();

  final RxnString appVersion = RxnString();
  final RxnString buildNumber = RxnString();
  final Rx<VersionCheckSummary?> versionSummary =
      Rx<VersionCheckSummary?>(null);
  final RxBool isVersionChecking = false.obs;
  final RxnString versionError = RxnString();

  final UpdateService _updateService = const UpdateService();

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = box.read('isDarkMode') ?? false;
    refreshVersionInfo();
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    box.write('isDarkMode', isDarkMode.value);
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> refreshVersionInfo({bool force = false}) async {
    final rawVersion = await _loadLocalVersion();

    if (isVersionChecking.value && !force) {
      return;
    }

    isVersionChecking.value = true;
    versionError.value = null;

    try {
      final summary = await _updateService.fetchVersionSummary(
        overrideCurrentVersion: rawVersion,
      );
      if (summary != null) {
        versionSummary.value = summary;
        _applyDisplayVersion(summary);
      }
    } catch (e) {
      versionError.value = 'Không thể kiểm tra cập nhật: ${e.toString()}';
    } finally {
      isVersionChecking.value = false;
    }
  }

  void applyVersionSummary(VersionCheckSummary summary) {
    versionSummary.value = summary;
    _applyDisplayVersion(summary);
    versionError.value = null;
  }

  Future<String?> _loadLocalVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion.value = UpdateService.sanitizeVersionForDisplay(info.version);
      buildNumber.value = info.buildNumber;
      final rawVersion = info.version.trim();
      return rawVersion.isEmpty ? null : rawVersion;
    } catch (_) {
      // Bỏ qua lỗi đọc phiên bản cục bộ
      return null;
    }
  }

  void _applyDisplayVersion(VersionCheckSummary summary) {
    if (!summary.updateAvailable) {
      final String? serverVersion = summary.effectiveLatestVersion;
      if (serverVersion != null && serverVersion.trim().isNotEmpty) {
        appVersion.value =
            UpdateService.sanitizeVersionForDisplay(serverVersion);
        return;
      }
    }
    appVersion.value = summary.currentVersion;
  }
}
