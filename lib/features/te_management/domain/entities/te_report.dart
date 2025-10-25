import 'package:equatable/equatable.dart';

class TEReportRowEntity extends Equatable {
  const TEReportRowEntity({
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
  });

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

  int get totalPass => pass + repairPass;

  bool contentEquals(TEReportRowEntity other) {
    return wipQty == other.wipQty &&
        input == other.input &&
        firstFail == other.firstFail &&
        repairQty == other.repairQty &&
        firstPass == other.firstPass &&
        repairPass == other.repairPass &&
        pass == other.pass &&
        fpr == other.fpr &&
        spr == other.spr &&
        yr == other.yr &&
        rr == other.rr;
  }

  @override
  List<Object?> get props => [
        modelName,
        groupName,
        wipQty,
        input,
        firstFail,
        repairQty,
        firstPass,
        repairPass,
        pass,
        fpr,
        spr,
        yr,
        rr,
      ];
}

class TEReportGroupEntity extends Equatable {
  const TEReportGroupEntity({
    required this.modelName,
    required this.rows,
  });

  final String modelName;
  final List<TEReportRowEntity> rows;

  bool get hasData => rows.isNotEmpty;

  @override
  List<Object?> get props => [modelName, rows];
}

class TEErrorDetailEntity extends Equatable {
  const TEErrorDetailEntity({
    required this.byErrorCode,
    required this.byMachine,
  });

  final List<TEErrorDetailClusterEntity> byErrorCode;
  final List<TEErrorDetailClusterEntity> byMachine;

  bool get hasData => byErrorCode.isNotEmpty || byMachine.isNotEmpty;

  @override
  List<Object?> get props => [byErrorCode, byMachine];
}

class TEErrorDetailClusterEntity extends Equatable {
  const TEErrorDetailClusterEntity({
    required this.label,
    required this.totalFail,
    required this.breakdowns,
    required this.isMachineCluster,
  });

  final String label;
  final int totalFail;
  final List<TEErrorDetailBreakdownEntity> breakdowns;
  final bool isMachineCluster;

  bool get hasBreakdown => breakdowns.isNotEmpty;

  @override
  List<Object?> get props => [label, totalFail, breakdowns, isMachineCluster];
}

class TEErrorDetailBreakdownEntity extends Equatable {
  const TEErrorDetailBreakdownEntity({
    required this.label,
    required this.failQty,
  });

  final String label;
  final int failQty;

  @override
  List<Object?> get props => [label, failQty];
}
