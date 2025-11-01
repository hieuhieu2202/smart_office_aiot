import '../../domain/entities/te_top_error.dart';

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  final text = value?.toString() ?? '';
  if (text.isEmpty) return 0;
  return int.tryParse(text) ?? double.tryParse(text)?.round() ?? 0;
}

double _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  final text = value?.toString() ?? '';
  if (text.isEmpty) return 0;
  return double.tryParse(text) ?? 0;
}

String _readString(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) {
    return json[key]?.toString().trim() ?? '';
  }
  final lower = key.toLowerCase();
  for (final entry in json.entries) {
    if (entry.key.toLowerCase() == lower) {
      return entry.value?.toString().trim() ?? '';
    }
  }
  return '';
}

class TETopErrorDetailModel extends TETopErrorDetailEntity {
  TETopErrorDetailModel({
    required super.modelName,
    required super.groupName,
    required super.firstFail,
    required super.repairFail,
  });

  factory TETopErrorDetailModel.fromJson(
    String modelName,
    Map<String, dynamic> json,
  ) {
    return TETopErrorDetailModel(
      modelName: modelName.trim().isEmpty ? '(N/A)' : modelName.trim(),
      groupName: _readString(json, 'GROUP_NAME'),
      firstFail: _parseInt(json['F_FAIL'] ?? json['FIRST_FAIL']),
      repairFail: _parseInt(json['R_FAIL'] ?? json['REPAIR_FAIL']),
    );
  }
}

class TETopErrorModel extends TETopErrorEntity {
  TETopErrorModel({
    required super.errorCode,
    required super.firstFailCount,
    required super.repairFailCount,
    required super.details,
  });

  factory TETopErrorModel.fromJson(Map<String, dynamic> json) {
    final errorCode = _readString(json, 'ERROR_CODE');
    final List<TETopErrorDetailModel> details = [];
    for (final entry in json.entries) {
      final key = entry.key;
      final lowerKey = key.toLowerCase();
      if (lowerKey == 'error_code' ||
          lowerKey == 'f_fail' ||
          lowerKey == 'r_fail') {
        continue;
      }
      final value = entry.value;
      if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            details.add(TETopErrorDetailModel.fromJson(key, item));
          } else if (item is Map) {
            details.add(TETopErrorDetailModel.fromJson(
              key,
              Map<String, dynamic>.from(item),
            ));
          }
        }
      }
    }
    details.sort((a, b) => b.totalFail.compareTo(a.totalFail));

    return TETopErrorModel(
      errorCode: errorCode,
      firstFailCount: _parseInt(json['F_FAIL']),
      repairFailCount: _parseInt(json['R_FAIL']),
      details: details,
    );
  }
}

class TETopErrorTrendPointModel extends TETopErrorTrendPointEntity {
  TETopErrorTrendPointModel({
    required super.label,
    required super.firstFail,
    required super.repairFail,
  });

  factory TETopErrorTrendPointModel.fromJson(Map<String, dynamic> json) {
    final label = _readString(json, 'WORK_DATE').isNotEmpty
        ? _readString(json, 'WORK_DATE')
        : _readString(json, 'WEEK');
    return TETopErrorTrendPointModel(
      label: label,
      firstFail: _parseDouble(json['F_FAIL']),
      repairFail: _parseDouble(json['R_FAIL']),
    );
  }
}
