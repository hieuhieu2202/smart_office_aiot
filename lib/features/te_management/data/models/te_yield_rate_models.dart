import 'dart:convert';

import '../../domain/entities/te_yield_rate.dart';

class TEYieldDetailModel extends TEYieldDetailEntity {
  TEYieldDetailModel({
    required List<String> dates,
    required List<TEYieldDetailRowEntity> rows,
  }) : super(dates: dates, rows: rows);

  factory TEYieldDetailModel.fromJson(dynamic json) {
    if (json is String && json.trim().isNotEmpty) {
      return TEYieldDetailModel.fromJson(jsonDecode(json));
    }
    if (json is! List) {
      return TEYieldDetailModel(dates: const [], rows: const []);
    }
    if (json.isEmpty) {
      return TEYieldDetailModel(dates: const [], rows: const []);
    }

    final header = json.first;
    final dates = <String>[];
    if (header is Map<String, dynamic>) {
      final rawDates = header['DATE'] ?? header['date'];
      if (rawDates is List) {
        for (final item in rawDates) {
          final value = item?.toString() ?? '';
          if (value.isNotEmpty) {
            dates.add(value);
          }
        }
      }
    }

    final rows = <TEYieldDetailRowEntity>[];
    for (final item in json.skip(1)) {
      if (item is Map<String, dynamic>) {
        rows.add(TEYieldDetailRowModel.fromMap(item));
      }
    }

    return TEYieldDetailModel(dates: dates, rows: rows);
  }
}

class TEYieldDetailRowModel extends TEYieldDetailRowEntity {
  TEYieldDetailRowModel({
    required super.modelName,
    required List<String> groupNames,
    required Map<String, List<int?>> input,
    required Map<String, List<int?>> firstFail,
    required Map<String, List<int?>> repairQty,
    required Map<String, List<int?>> pass,
    required Map<String, List<double?>> yieldRate,
  }) : super(
          groupNames: groupNames,
          input: input,
          firstFail: firstFail,
          repairQty: repairQty,
          pass: pass,
          yieldRate: yieldRate,
        );

  factory TEYieldDetailRowModel.fromMap(Map<String, dynamic> map) {
    final modelName = _readString(map, 'MODEL_NAME');
    final groupNames = _readList(map, 'GROUP_NAME')
        .map((value) => value?.toString().trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toList();

    Map<String, dynamic>? readMetric(String key) {
      final value = map[key] ?? map[key.toLowerCase()];
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is List && value.isNotEmpty && value.first is Map) {
        return Map<String, dynamic>.from(value.first as Map);
      }
      return null;
    }

    Map<String, List<int?>> parseIntMetric(String key) {
      final metric = readMetric(key);
      if (metric == null) {
        return {};
      }
      final result = <String, List<int?>>{};
      for (final group in groupNames) {
        final values = metric[group];
        result[group] = _parseIntList(values);
      }
      return result;
    }

    Map<String, List<double?>> parseDoubleMetric(String key) {
      final metric = readMetric(key);
      if (metric == null) {
        return {};
      }
      final result = <String, List<double?>>{};
      for (final group in groupNames) {
        final values = metric[group];
        result[group] = _parseDoubleList(values);
      }
      return result;
    }

    return TEYieldDetailRowModel(
      modelName: modelName.isEmpty ? '(N/A)' : modelName,
      groupNames: groupNames,
      input: parseIntMetric('INPUT'),
      firstFail: parseIntMetric('FIRST_FAIL'),
      repairQty: parseIntMetric('SECOND_FAIL'),
      pass: parseIntMetric('PASS'),
      yieldRate: parseDoubleMetric('YR'),
    );
  }
}

List<dynamic> _readList(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is List) {
    return value;
  }
  final lower = key.toLowerCase();
  for (final entry in map.entries) {
    if (entry.key.toLowerCase() == lower && entry.value is List) {
      return entry.value as List;
    }
  }
  return const [];
}

String _readString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is String) {
    return value.trim();
  }
  final lower = key.toLowerCase();
  for (final entry in map.entries) {
    if (entry.key.toLowerCase() == lower) {
      return entry.value?.toString().trim() ?? '';
    }
  }
  return '';
}

List<int?> _parseIntList(dynamic value) {
  if (value is List) {
    return List<int?>.unmodifiable(value.map(_toIntOrNull));
  }
  return const [];
}

List<double?> _parseDoubleList(dynamic value) {
  if (value is List) {
    return List<double?>.unmodifiable(value.map(_toDoubleOrNull));
  }
  return const [];
}

int? _toIntOrNull(dynamic value) {
  final normalized = _normalize(value);
  if (normalized == null) {
    return null;
  }
  final parsed = int.tryParse(normalized);
  if (parsed != null) {
    return parsed;
  }
  final asDouble = double.tryParse(normalized);
  return asDouble?.round();
}

double? _toDoubleOrNull(dynamic value) {
  final normalized = _normalize(value);
  if (normalized == null) {
    return null;
  }
  final parsed = double.tryParse(normalized);
  if (parsed == null) {
    return null;
  }
  if (parsed.isNaN || !parsed.isFinite) {
    return null;
  }
  final clamped = parsed.clamp(0, 100);
  return (clamped is double) ? clamped : clamped.toDouble();
}

String? _normalize(dynamic value) {
  if (value == null) {
    return null;
  }
  final str = value.toString().trim();
  if (str.isEmpty || str.toUpperCase() == 'NULL') {
    return null;
  }
  return str;
}
