import 'package:smart_factory/model/notification_message.dart';

class VersionCheckSummary {
  const VersionCheckSummary({
    required this.currentVersion,
    required this.platform,
    required this.updateAvailable,
    this.serverVersion,
    this.minSupported,
    this.notes,
    this.downloadUrl,
    this.latestRelease,
  });

  final String currentVersion;
  final String platform;
  final bool updateAvailable;
  final String? serverVersion;
  final String? minSupported;
  final String? notes;
  final String? downloadUrl;
  final NotificationAppVersion? latestRelease;

  String? get effectiveLatestVersion =>
      serverVersion ?? latestRelease?.versionName;

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
