import 'dart:collection';

class TEReportRow {
  TEReportRow({
    required this.modelName,
    required this.groupName,
    required this.wipQty,
    required this.input,
    required this.firstFail,
    required this.repairQty,
    required this.firstPass,
    required this.repairPass,
    required this.pass,
    required this.fpr,
    required this.spr,
    required this.yr,
    required this.rr,
    required this.raw,
  });

  factory TEReportRow.fromMap(Map<String, dynamic> map) {
    int _parseInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.round();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double _parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    String _readString(String key) {
      final value = map[key];
      if (value == null) return '';
      return value.toString();
    }

    final groupName = (_readString('GROUP_NAME').isNotEmpty
            ? _readString('GROUP_NAME')
            : _readString('group_name'))
        .trim();
    final modelName = (_readString('MODEL_NAME').isNotEmpty
            ? _readString('MODEL_NAME')
            : _readString('model_name'))
        .trim();

    return TEReportRow(
      modelName: modelName,
      groupName: groupName,
      wipQty: _parseInt(map['WIP_QTY']),
      input: _parseInt(map['INPUT']),
      firstFail: _parseInt(map['FIRST_FAIL']),
      repairQty: _parseInt(map['REPAIR_QTY']),
      firstPass: _parseInt(map['FIRST_PASS']),
      repairPass: _parseInt(map['R_PASS']),
      pass: _parseInt(map['PASS']),
      fpr: _parseDouble(map['FPR']),
      spr: _parseDouble(map['SPR'] ?? map['SPF'] ?? map['S.P.R']),
      yr: _parseDouble(map['YR'] ?? map['Y.R']),
      rr: _parseDouble(map['RR'] ?? map['R.R']),
      raw: Map<String, dynamic>.from(map),
    );
  }

  final String modelName;
  final String groupName;
  final int wipQty;
  final int input;
  final int firstFail;
  final int repairQty;
  final int firstPass;
  final int repairPass;
  final int pass;
  final double fpr;
  final double spr;
  final double yr;
  final double rr;
  final Map<String, dynamic> raw;

  int get totalPass => pass + repairPass;

  bool matches(String query) {
    final q = query.toLowerCase();
    if (modelName.toLowerCase().contains(q)) return true;
    if (groupName.toLowerCase().contains(q)) return true;

    final values = <String>[
      wipQty.toString(),
      input.toString(),
      firstFail.toString(),
      repairQty.toString(),
      firstPass.toString(),
      repairPass.toString(),
      pass.toString(),
      totalPass.toString(),
      fpr.toStringAsFixed(2),
      spr.toStringAsFixed(2),
      yr.toStringAsFixed(2),
      rr.toStringAsFixed(2),
    ];
    return values.any((v) => v.toLowerCase().contains(q));
  }

  Map<String, dynamic> toExportMap({String? indexLabel}) {
    final map = LinkedHashMap<String, dynamic>.from(raw);
    if (indexLabel != null) {
      map['#'] = indexLabel;
    }
    map['TOTAL_PASS'] = totalPass;
    map['FPR'] = fpr;
    map['SPR'] = spr;
    map['YR'] = yr;
    map['RR'] = rr;
    return map;
  }
}

class TEReportGroup {
  const TEReportGroup({required this.modelName, required this.rows});

  factory TEReportGroup.fromMaps(List<Map<String, dynamic>> maps) {
    if (maps.isEmpty) {
      return const TEReportGroup(modelName: '', rows: []);
    }
    final rows = <TEReportRow>[];
    for (final map in maps) {
      rows.add(TEReportRow.fromMap(map));
    }
    final modelName = rows.isEmpty ? '' : rows.first.modelName;
    return TEReportGroup(modelName: modelName, rows: rows);
  }

  final String modelName;
  final List<TEReportRow> rows;

  bool get hasData => rows.isNotEmpty;

  TEReportGroup copyWith({List<TEReportRow>? rows}) =>
      TEReportGroup(modelName: modelName, rows: rows ?? this.rows);
}

class TEErrorDetail {
  const TEErrorDetail({
    required this.byErrorCode,
    required this.byMachine,
  });

  factory TEErrorDetail.fromJson(Map<String, dynamic> json) {
    List<dynamic> _readList(String key) {
      final raw = json[key];
      if (raw is List) return raw;
      return const [];
    }

    return TEErrorDetail(
      byErrorCode: _readList('ByErrorCode')
          .map((item) => TEErrorDetailCluster.fromDynamicList(item))
          .where((cluster) => cluster != null)
          .map((cluster) => cluster!)
          .toList(),
      byMachine: _readList('ByMachine')
          .map((item) => TEErrorDetailCluster.fromDynamicList(item))
          .where((cluster) => cluster != null)
          .map((cluster) => cluster!)
          .toList(),
    );
  }

  final List<TEErrorDetailCluster> byErrorCode;
  final List<TEErrorDetailCluster> byMachine;

  bool get hasData => byErrorCode.isNotEmpty || byMachine.isNotEmpty;
}

class TEErrorDetailCluster {
  const TEErrorDetailCluster({
    required this.label,
    required this.totalFail,
    required this.breakdowns,
  });

  factory TEErrorDetailCluster.fromMaps(List<Map<String, dynamic>> maps) {
    if (maps.isEmpty) {
      return const TEErrorDetailCluster(label: '', totalFail: 0, breakdowns: []);
    }
    final head = maps.first;
    final label = _string(head['ERROR_CODE']) ?? _string(head['MACHINE_NAME']) ?? '';
    final total = _int(head['FAIL_QTY']);
    final breakdowns = <TEErrorDetailBreakdown>[];
    for (final map in maps.skip(1)) {
      final breakdownLabel =
          _string(map['MACHINE_NAME']) ?? _string(map['ERROR_CODE']) ?? '';
      if (breakdownLabel.isEmpty) {
        continue;
      }
      breakdowns.add(
        TEErrorDetailBreakdown(
          label: breakdownLabel,
          failQty: _int(map['FAIL_QTY']),
        ),
      );
    }
    return TEErrorDetailCluster(
      label: label,
      totalFail: total,
      breakdowns: breakdowns,
    );
  }

  static TEErrorDetailCluster? fromDynamicList(dynamic raw) {
    if (raw is List) {
      final maps = <Map<String, dynamic>>[];
      for (final item in raw) {
        if (item is Map) {
          maps.add(item.map(
            (key, value) => MapEntry(key.toString(), value),
          ));
        }
      }
      return TEErrorDetailCluster.fromMaps(maps);
    }
    return null;
  }

  final String label;
  final int totalFail;
  final List<TEErrorDetailBreakdown> breakdowns;

  bool get hasBreakdown => breakdowns.isNotEmpty;
}

class TEErrorDetailBreakdown {
  const TEErrorDetailBreakdown({required this.label, required this.failQty});

  final String label;
  final int failQty;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _string(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}
