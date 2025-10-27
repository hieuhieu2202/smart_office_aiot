import '../../domain/entities/te_report.dart';

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _parseDouble(dynamic value) {
  if (value is double) return double.parse(value.toStringAsFixed(2));
  if (value is int) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _readString(Map<String, dynamic> map, String key) {
  if (map.containsKey(key)) {
    final value = map[key];
    return value?.toString().trim() ?? '';
  }
  final lower = key.toLowerCase();
  for (final entry in map.entries) {
    if (entry.key.toLowerCase() == lower) {
      return entry.value?.toString().trim() ?? '';
    }
  }
  return '';
}

List<dynamic> _readList(Map<String, dynamic> json, String key) {
  if (json[key] is List) {
    return json[key] as List<dynamic>;
  }
  final lower = key.toLowerCase();
  for (final entry in json.entries) {
    if (entry.key.toLowerCase() == lower && entry.value is List) {
      return entry.value as List<dynamic>;
    }
  }
  return const [];
}

dynamic _lookup(Map<String, dynamic> map, String key) {
  if (map.containsKey(key)) {
    return map[key];
  }
  final lower = key.toLowerCase();
  for (final entry in map.entries) {
    if (entry.key.toLowerCase() == lower) {
      return entry.value;
    }
  }
  return null;
}

String _normalize(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

class TEReportRowModel extends TEReportRowEntity {
  TEReportRowModel({
    required super.modelName,
    required super.groupName,
    required super.wipQty,
    required super.input,
    required super.firstFail,
    required super.repairQty,
    required super.firstPass,
    required super.repairPass,
    required super.pass,
    required super.fpr,
    required super.spr,
    required super.yr,
    required super.rr,
  });

  factory TEReportRowModel.fromJson(Map<String, dynamic> json) {
    final model = _readString(json, 'MODEL_NAME');
    final group = _readString(json, 'GROUP_NAME');
    return TEReportRowModel(
      modelName: model.isEmpty ? '(N/A)' : model,
      groupName: group,
      wipQty: _parseInt(json['WIP_QTY']),
      input: _parseInt(json['INPUT']),
      firstFail: _parseInt(json['FIRST_FAIL']),
      repairQty: _parseInt(json['REPAIR_QTY']),
      firstPass: _parseInt(json['FIRST_PASS']),
      repairPass: _parseInt(json['R_PASS']),
      pass: _parseInt(json['PASS']),
      fpr: double.parse(_parseDouble(json['FPR']).toStringAsFixed(2)),
      spr: double.parse(
        _parseDouble(json['SPR'] ?? json['SPF'] ?? json['S.P.R']).toStringAsFixed(2),
      ),
      yr: double.parse(
        _parseDouble(json['YR'] ?? json['Y.R']).toStringAsFixed(2),
      ),
      rr: double.parse(_parseDouble(json['RR'] ?? json['R.R']).toStringAsFixed(2)),
    );
  }
}

class TEReportGroupModel extends TEReportGroupEntity {
  TEReportGroupModel({
    required super.modelName,
    required super.rows,
  });

  factory TEReportGroupModel.fromRows(List<TEReportRowEntity> rows) {
    if (rows.isEmpty) {
      return TEReportGroupModel(modelName: '(N/A)', rows: const []);
    }
    final sorted = List<TEReportRowEntity>.from(rows)
      ..sort((a, b) => a.groupName.compareTo(b.groupName));
    final model = sorted.first.modelName;
    return TEReportGroupModel(modelName: model, rows: sorted);
  }
}

class TEErrorDetailModel extends TEErrorDetailEntity {
  TEErrorDetailModel({
    required super.byErrorCode,
    required super.byMachine,
  });

  factory TEErrorDetailModel.fromJson(Map<String, dynamic> json) {
    return TEErrorDetailModel(
      byErrorCode: _readList(json, 'ByErrorCode')
          .map((item) => TEErrorDetailClusterModel.fromDynamic(item))
          .whereType<TEErrorDetailClusterModel>()
          .toList(),
      byMachine: _readList(json, 'ByMachine')
          .map((item) => TEErrorDetailClusterModel.fromDynamic(item))
          .whereType<TEErrorDetailClusterModel>()
          .toList(),
    );
  }
}

class TEErrorDetailClusterModel extends TEErrorDetailClusterEntity {
  TEErrorDetailClusterModel({
    required super.label,
    required super.totalFail,
    required super.breakdowns,
    required super.isMachineCluster,
  });

  factory TEErrorDetailClusterModel.fromMaps(List<Map<String, dynamic>> maps) {
    if (maps.isEmpty) {
      return TEErrorDetailClusterModel(
        label: '',
        totalFail: 0,
        breakdowns: const [],
        isMachineCluster: false,
      );
    }

    final head = maps.first;
    final headError = _normalize(_lookup(head, 'ERROR_CODE'));
    final headMachine = _normalize(_lookup(head, 'MACHINE_NAME'));
    final isMachineCluster = headMachine.isNotEmpty && headError.isEmpty;
    final initialLabel = isMachineCluster
        ? headMachine
        : (headError.isNotEmpty ? headError : headMachine);

    final total = _parseInt(_lookup(head, 'FAIL_QTY'));
    final breakdowns = <TEErrorDetailBreakdownEntity>[];

    for (final map in maps.skip(1)) {
      final breakdownError = _normalize(_lookup(map, 'ERROR_CODE'));
      final breakdownMachine = _normalize(_lookup(map, 'MACHINE_NAME'));
      final breakdownLabel = isMachineCluster
          ? (breakdownError.isNotEmpty ? breakdownError : breakdownMachine)
          : (breakdownMachine.isNotEmpty ? breakdownMachine : breakdownError);
      breakdowns.add(
        TEErrorDetailBreakdownEntity(
          label: breakdownLabel,
          failQty: _parseInt(_lookup(map, 'FAIL_QTY')),
        ),
      );
    }

    var resolvedLabel = initialLabel;
    if (resolvedLabel.isEmpty) {
      for (final breakdown in breakdowns) {
        if (breakdown.label.trim().isNotEmpty) {
          resolvedLabel = breakdown.label.trim();
          break;
        }
      }
    }

    return TEErrorDetailClusterModel(
      label: resolvedLabel,
      totalFail: total,
      breakdowns: breakdowns,
      isMachineCluster: isMachineCluster,
    );
  }

  static TEErrorDetailClusterModel? fromDynamic(dynamic raw) {
    if (raw is List) {
      final maps = <Map<String, dynamic>>[];
      for (final item in raw) {
        if (item is Map) {
          maps.add(item.map(
            (key, value) => MapEntry(key.toString(), value),
          ));
        }
      }
      return TEErrorDetailClusterModel.fromMaps(maps);
    }
    return null;
  }
}
