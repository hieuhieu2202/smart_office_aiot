import 'dart:collection';

import 'package:equatable/equatable.dart';

class TETopErrorEntity extends Equatable {
  TETopErrorEntity({
    required this.errorCode,
    required int firstFailCount,
    required int repairFailCount,
    required List<TETopErrorDetailEntity> details,
  })  : firstFail = firstFailCount,
        repairFail = repairFailCount,
        details = UnmodifiableListView(details);

  final String errorCode;
  final int firstFail;
  final int repairFail;
  final UnmodifiableListView<TETopErrorDetailEntity> details;

  int get totalFail => firstFail + repairFail;

  @override
  List<Object?> get props => [errorCode, firstFail, repairFail, details];
}

class TETopErrorDetailEntity extends Equatable {
  const TETopErrorDetailEntity({
    required this.modelName,
    required this.groupName,
    required this.firstFail,
    required this.repairFail,
  });

  final String modelName;
  final String groupName;
  final int firstFail;
  final int repairFail;

  int get totalFail => firstFail + repairFail;

  @override
  List<Object?> get props => [modelName, groupName, firstFail, repairFail];
}

class TETopErrorTrendPointEntity extends Equatable {
  const TETopErrorTrendPointEntity({
    required this.label,
    required this.firstFail,
    required this.repairFail,
  });

  final String label;
  final double firstFail;
  final double repairFail;

  double get total => firstFail + repairFail;

  @override
  List<Object?> get props => [label, firstFail, repairFail];
}
