import '../../domain/entities/resistor_machine_entities.dart';

class ResistorMachineSummaryModel extends ResistorMachineSummary {
  ResistorMachineSummaryModel({
    required super.wip,
    required super.pass,
    required super.fail,
    required super.firstFail,
    required super.retest,
    required super.yieldRate,
    required super.retestRate,
  });

  factory ResistorMachineSummaryModel.fromJson(Map<String, dynamic> json) {
    return ResistorMachineSummaryModel(
      wip: _readInt(json, 'WIP'),
      pass: _readInt(json, 'PASS'),
      fail: _readInt(json, 'FAIL'),
      firstFail: _readInt(json, 'FIRST_FAIL'),
      retest: _readInt(json, 'RETEST'),
      yieldRate: _readDouble(json, 'YR'),
      retestRate: _readDouble(json, 'RR'),
    );
  }
}

class ResistorMachineOutputModel extends ResistorMachineOutput {
  ResistorMachineOutputModel({
    required super.section,
    required super.workDate,
    required super.startTime,
    required super.pass,
    required super.fail,
    required super.firstFail,
    required super.retest,
    required super.yieldRate,
    required super.retestRate,
  });

  factory ResistorMachineOutputModel.fromJson(Map<String, dynamic> json) {
    return ResistorMachineOutputModel(
      section: _readNullableInt(json, 'SECTION'),
      workDate: _readString(json, 'WORKDATE'),
      startTime: _readDateTime(json, const <String>['START_TIME', 'STARTTIME', 'TIME_START', 'TIMESTART']),
      pass: _readInt(json, 'PASS'),
      fail: _readInt(json, 'FAIL'),
      firstFail: _readInt(json, 'FIRST_FAIL'),
      retest: _readInt(json, 'RETEST'),
      yieldRate: _readDouble(json, 'YR'),
      retestRate: _readDouble(json, 'RR'),
    );
  }
}

DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    if (value == null) continue;
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (_) {
        continue;
      }
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      DateTime? parsed = DateTime.tryParse(trimmed);
      if (parsed != null) {
        return parsed;
      }
      final normalized = trimmed.replaceAll('/', '-');
      parsed = DateTime.tryParse(normalized);
      if (parsed != null) {
        return parsed;
      }
      if (trimmed.contains(' ')) {
        final iso = trimmed.replaceFirst(' ', 'T');
        parsed = DateTime.tryParse(iso);
        if (parsed != null) {
          return parsed;
        }
        final normalizedIso = normalized.replaceFirst(' ', 'T');
        parsed = DateTime.tryParse(normalizedIso);
        if (parsed != null) {
          return parsed;
        }
      }
    }
  }
  return null;
}

class ResistorMachineInfoModel extends ResistorMachineInfo {
  ResistorMachineInfoModel({
    required super.name,
    required super.pass,
    required super.fail,
    required super.firstFail,
    required super.retest,
    required super.yieldRate,
    required super.retestRate,
  });

  factory ResistorMachineInfoModel.fromJson(Map<String, dynamic> json) {
    return ResistorMachineInfoModel(
      name: _readString(json, 'NAME') ?? '',
      pass: _readInt(json, 'PASS'),
      fail: _readInt(json, 'FAIL'),
      firstFail: _readInt(json, 'FIRST_FAIL'),
      retest: _readInt(json, 'RETEST'),
      yieldRate: _readDouble(json, 'YR'),
      retestRate: _readDouble(json, 'RR'),
    );
  }
}

class ResistorMachineTrackingDataModel extends ResistorMachineTrackingData {
  ResistorMachineTrackingDataModel({
    required ResistorMachineSummary summary,
    required List<ResistorMachineOutput> outputs,
    required List<ResistorMachineInfo> machines,
  }) : super(summary: summary, outputs: outputs, machines: machines);

  factory ResistorMachineTrackingDataModel.fromJson(Map<String, dynamic> json) {
    final summaryJson = (json['summary'] ?? json['Summary'] ??
        <String, dynamic>{}) as Map<String, dynamic>;
    final summary = ResistorMachineSummaryModel.fromJson(summaryJson);

    final outputsRaw =
        (json['outputs'] ?? json['Outputs'] ?? const <dynamic>[]) as List<dynamic>;
    final outputsList = outputsRaw
        .whereType<Map<String, dynamic>>()
        .map(ResistorMachineOutputModel.fromJson)
        .toList();

    final machinesRaw =
        (json['machines'] ?? json['Machines'] ?? const <dynamic>[]) as List<dynamic>;
    final machines = machinesRaw
        .whereType<Map<String, dynamic>>()
        .map(ResistorMachineInfoModel.fromJson)
        .toList();

    return ResistorMachineTrackingDataModel(
      summary: summary,
      outputs: outputsList,
      machines: machines,
    );
  }
}

double _toDouble(dynamic value) {
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

double _readDouble(Map<String, dynamic> json, String key) {
  final value = _valueForKey(json, key);
  return _toDouble(value);
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = _valueForKey(json, key);
  if (value == null) {
    return 0;
  }
  return _toInt(value);
}

int? _readNullableInt(Map<String, dynamic> json, String key) {
  final value = _valueForKey(json, key);
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

String? _readString(Map<String, dynamic> json, String key) {
  final value = _valueForKey(json, key);
  if (value == null) {
    return null;
  }
  return value.toString();
}

dynamic _valueForKey(Map<String, dynamic> json, String key) {
  final lookup = _normalizeKey(key);
  for (final entry in json.entries) {
    if (_normalizeKey(entry.key.toString()) == lookup) {
      return entry.value;
    }
  }
  return null;
}

String _normalizeKey(String key) {
  return key.toLowerCase().replaceAll(RegExp(r'[_\s]'), '');
}
