import 'dart:collection';

import 'package:equatable/equatable.dart';

class TEYieldDetailEntity extends Equatable {
  TEYieldDetailEntity({
    required List<String> dates,
    required List<TEYieldDetailRowEntity> rows,
  })  : dates = UnmodifiableListView(dates),
        rows = UnmodifiableListView(rows);

  factory TEYieldDetailEntity.empty() {
    return TEYieldDetailEntity(
      dates: const <String>[],
      rows: const <TEYieldDetailRowEntity>[],
    );
  }

  final UnmodifiableListView<String> dates;
  final UnmodifiableListView<TEYieldDetailRowEntity> rows;

  bool get hasData => dates.isNotEmpty && rows.isNotEmpty;

  @override
  List<Object?> get props => [dates, rows];
}

class TEYieldDetailRowEntity extends Equatable {
  TEYieldDetailRowEntity({
    required this.modelName,
    required List<String> groupNames,
    required Map<String, List<int?>> input,
    required Map<String, List<int?>> firstFail,
    required Map<String, List<int?>> repairQty,
    required Map<String, List<int?>> pass,
    required Map<String, List<double?>> yieldRate,
  })  : groupNames = UnmodifiableListView(groupNames),
        input = _freezeIntMap(input),
        firstFail = _freezeIntMap(firstFail),
        repairQty = _freezeIntMap(repairQty),
        pass = _freezeIntMap(pass),
        yieldRate = _freezeDoubleMap(yieldRate);

  final String modelName;
  final UnmodifiableListView<String> groupNames;
  final Map<String, List<int?>> input;
  final Map<String, List<int?>> firstFail;
  final Map<String, List<int?>> repairQty;
  final Map<String, List<int?>> pass;
  final Map<String, List<double?>> yieldRate;

  bool get hasGroups => groupNames.isNotEmpty;

  @override
  List<Object?> get props => [
        modelName,
        groupNames,
        input,
        firstFail,
        repairQty,
        pass,
        yieldRate,
      ];
}

Map<String, List<int?>> _freezeIntMap(Map<String, List<int?>> source) {
  return Map.unmodifiable({
    for (final entry in source.entries)
      entry.key: UnmodifiableListView<int?>(entry.value),
  });
}

Map<String, List<double?>> _freezeDoubleMap(Map<String, List<double?>> source) {
  return Map.unmodifiable({
    for (final entry in source.entries)
      entry.key: UnmodifiableListView<double?>(entry.value),
  });
}

String buildYieldCellKey(String modelName, String groupName, int columnIndex) {
  return '$modelName|$groupName|$columnIndex';
}
