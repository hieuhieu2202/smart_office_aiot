class AppFileInfo {
  final String? fileName;
  final String? relativePath;
  final int? sizeBytes;
  final String? sha256;
  final String? contentType;

  const AppFileInfo({
    this.fileName,
    this.relativePath,
    this.sizeBytes,
    this.sha256,
    this.contentType,
  });

  factory AppFileInfo.fromJson(Map<String, dynamic> json) => AppFileInfo(
        fileName: json['fileName'] as String?,
        relativePath: json['relativePath'] as String?,
        sizeBytes: json['sizeBytes'] as int?,
        sha256: json['sha256'] as String?,
        contentType: json['contentType'] as String?,
      );
}

class AppVersionInfo {
  final String latest;
  final String minSupported;
  final String? notesVi;
  final String? notesEn;
  final int build;
  final DateTime updatedAt;
  final Map<String, AppFileInfo>? files;

  AppVersionInfo({
    required this.latest,
    required this.minSupported,
    this.notesVi,
    this.notesEn,
    required this.build,
    required this.updatedAt,
    this.files,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? filesJson =
        json['files'] as Map<String, dynamic>?;
    return AppVersionInfo(
      latest: json['latest'] as String? ?? '',
      minSupported: json['minSupported'] as String? ?? '',
      notesVi: json['notesVi'] as String?,
      notesEn: json['notesEn'] as String?,
      build: json['build'] is int ? json['build'] as int : 0,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      files: filesJson?.map(
        (key, value) => MapEntry(
          key,
          AppFileInfo.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }
}
