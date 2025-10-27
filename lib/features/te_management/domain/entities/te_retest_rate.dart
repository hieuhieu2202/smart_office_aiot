import 'dart:collection';

import 'package:equatable/equatable.dart';

class TERetestDetailEntity extends Equatable {
  const TERetestDetailEntity({
    required List<String> dates,
    required List<TERetestDetailRowEntity> rows,
  })  : dates = UnmodifiableListView(dates),
        rows = UnmodifiableListView(rows);

  TERetestDetailEntity.empty()
      : dates = const UnmodifiableListView<String>([]),
        rows = const UnmodifiableListView<TERetestDetailRowEntity>([]);

  final UnmodifiableListView<String> dates;
  final UnmodifiableListView<TERetestDetailRowEntity> rows;

  bool get hasData => dates.isNotEmpty && rows.isNotEmpty;

  @override
  List<Object?> get props => [dates, rows];
}

class TERetestDetailRowEntity extends Equatable {
  const TERetestDetailRowEntity({
    required this.modelName,
    required List<String> groupNames,
    required Map<String, List<int?>> input,
    required Map<String, List<int?>> firstFail,
    required Map<String, List<int?>> retestFail,
    required Map<String, List<int?>> pass,
    required Map<String, List<double?>> retestRate,
  })  : groupNames = UnmodifiableListView(groupNames),
        input = _freezeIntMap(input),
        firstFail = _freezeIntMap(firstFail),
        retestFail = _freezeIntMap(retestFail),
        pass = _freezeIntMap(pass),
        retestRate = _freezeDoubleMap(retestRate);

  final String modelName;
  final UnmodifiableListView<String> groupNames;
  final Map<String, List<int?>> input;
  final Map<String, List<int?>> firstFail;
  final Map<String, List<int?>> retestFail;
  final Map<String, List<int?>> pass;
  final Map<String, List<double?>> retestRate;

  bool get hasGroups => groupNames.isNotEmpty;

  @override
  List<Object?> get props => [
        modelName,
        groupNames,
        input,
        firstFail,
        retestFail,
        pass,
        retestRate,
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
