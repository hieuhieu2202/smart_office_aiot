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

    final groupName = (map['GROUP_NAME'] ?? '').toString();
    final modelName = (map['MODEL_NAME'] ?? '').toString();

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
