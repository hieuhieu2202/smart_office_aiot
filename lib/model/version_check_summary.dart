import 'package:smart_factory/model/notification_message.dart';

class VersionCheckSummary {
  const VersionCheckSummary({
    required this.currentVersion,
    required this.installedVersion,
    required this.platform,
    required this.updateAvailable,
    this.serverVersion,
    this.serverCurrentVersion,
    this.minSupported,
    this.notes,
    this.downloadUrl,
    this.latestRelease,
  });

  /// Giá trị hiển thị cho phiên bản hiện tại (ưu tiên dữ liệu server trả về).
  final String currentVersion;

  /// Phiên bản đã cài đặt trên thiết bị sau khi chuẩn hoá để so sánh.
  final String installedVersion;
  final String platform;
  final bool updateAvailable;
  final String? serverVersion;
  final String? serverCurrentVersion;
  final String? minSupported;
  final String? notes;
  final String? downloadUrl;
  final NotificationAppVersion? latestRelease;

  String? get effectiveLatestVersion =>
      serverVersion ?? latestRelease?.versionName;

  /// Phiên bản hiển thị trong UI (ưu tiên số liệu từ server).
  String get displayVersion => currentVersion;

  String? get releaseNotes =>
      (latestRelease?.releaseNotes?.trim().isNotEmpty ?? false)
          ? latestRelease!.releaseNotes!
          : (notes?.trim().isNotEmpty ?? false)
              ? notes!.trim()
              : null;

  String? get checksum => latestRelease?.fileChecksum;

  DateTime? get releaseDate => latestRelease?.releaseDate;

  String? get downloadFileName => latestRelease?.fileName;
}
