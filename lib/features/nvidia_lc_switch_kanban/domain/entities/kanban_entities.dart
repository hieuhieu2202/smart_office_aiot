import 'package:equatable/equatable.dart';

class KanbanRequest extends Equatable {
  const KanbanRequest({
    required this.modelSerial,
    required this.date,
    required this.shift,
    this.dateRange = 'string',
    this.groups = const <String>[],
    this.section = 'string',
    this.station = 'string',
    this.line = 'string',
    this.customer = 'string',
    this.nickName = 'string',
    this.modelName = 'string',
  });

  final String modelSerial;
  final String date; // yyyy-MM-dd
  final String shift;
  final String dateRange;
  final List<String> groups;
  final String section;
  final String station;
  final String line;
  final String customer;
  final String nickName;
  final String modelName;

  KanbanRequest copyWith({
    String? modelSerial,
    String? date,
    String? shift,
    String? dateRange,
    List<String>? groups,
    String? section,
    String? station,
    String? line,
    String? customer,
    String? nickName,
    String? modelName,
  }) {
    return KanbanRequest(
      modelSerial: modelSerial ?? this.modelSerial,
      date: date ?? this.date,
      shift: shift ?? this.shift,
      dateRange: dateRange ?? this.dateRange,
      groups: groups ?? this.groups,
      section: section ?? this.section,
      station: station ?? this.station,
      line: line ?? this.line,
      customer: customer ?? this.customer,
      nickName: nickName ?? this.nickName,
      modelName: modelName ?? this.modelName,
    );
  }

  Map<String, dynamic> toBody() {
    return <String, dynamic>{
      'modelSerial': modelSerial,
      'date': date,
      'shift': shift,
      'dateRange': dateRange,
      'groups': groups,
      'section': section,
      'station': station,
      'line': line,
      'customer': customer,
      'nickName': nickName,
      'modelName': modelName,
    };
  }

  @override
  List<Object?> get props => <Object?>[
        modelSerial,
        date,
        shift,
        dateRange,
        groups,
        section,
        station,
        line,
        customer,
        nickName,
        modelName,
      ];
}

class OutputTrackingEntity extends Equatable {
  const OutputTrackingEntity({
    required this.sections,
    required this.models,
    required this.groups,
  });

  final List<String> sections;
  final List<String> models;
  final List<OutputGroupEntity> groups;

  @override
  List<Object?> get props => <Object?>[sections, models, groups];
}

class OutputGroupEntity extends Equatable {
  const OutputGroupEntity({
    required this.groupName,
    required this.modelName,
    required this.pass,
    required this.fail,
    required this.yr,
    required this.rr,
    required this.wip,
  });

  final String groupName;
  final String modelName;
  final List<double> pass;
  final List<double> fail;
  final List<double> yr;
  final List<double> rr;
  final int wip;

  @override
  List<Object?> get props => <Object?>[
        groupName,
        modelName,
        pass,
        fail,
        yr,
        rr,
        wip,
      ];
}

class OutputTrackingDetailEntity extends Equatable {
  const OutputTrackingDetailEntity({
    required this.errorDetails,
    required this.testerDetails,
  });

  final List<ErrorDetailEntity> errorDetails;
  final List<TesterDetailEntity> testerDetails;

  @override
  List<Object?> get props => <Object?>[errorDetails, testerDetails];
}

class ErrorDetailEntity extends Equatable {
  const ErrorDetailEntity({
    required this.code,
    required this.failQty,
  });

  final String code;
  final int failQty;

  @override
  List<Object?> get props => <Object?>[code, failQty];
}

class TesterDetailEntity extends Equatable {
  const TesterDetailEntity({
    required this.stationName,
    required this.failQty,
  });

  final String stationName;
  final int failQty;

  @override
  List<Object?> get props => <Object?>[stationName, failQty];
}

class UphTrackingEntity extends Equatable {
  const UphTrackingEntity({
    required this.sections,
    required this.models,
    required this.groups,
  });

  final List<String> sections;
  final List<String> models;
  final List<UphGroupEntity> groups;

  @override
  List<Object?> get props => <Object?>[sections, models, groups];
}

class UphGroupEntity extends Equatable {
  const UphGroupEntity({
    required this.groupName,
    required this.pass,
    required this.pr,
    required this.wip,
    required this.uph,
  });

  final String groupName;
  final List<double> pass;
  final List<double> pr;
  final int wip;
  final double uph;

  @override
  List<Object?> get props => <Object?>[groupName, pass, pr, wip, uph];
}

class UpdTrackingEntity extends Equatable {
  const UpdTrackingEntity({
    required this.dates,
    required this.models,
    required this.groups,
  });

  final List<String> dates;
  final List<String> models;
  final List<UpdGroupEntity> groups;

  @override
  List<Object?> get props => <Object?>[dates, models, groups];
}

class UpdGroupEntity extends Equatable {
  const UpdGroupEntity({
    required this.groupName,
    required this.pass,
    required this.pr,
    required this.wip,
    required this.upd,
  });

  final String groupName;
  final List<double> pass;
  final List<double> pr;
  final int wip;
  final double upd;

  @override
  List<Object?> get props => <Object?>[groupName, pass, pr, wip, upd];
}

class OutputTrackingDetailParams extends Equatable {
  const OutputTrackingDetailParams({
    required this.modelSerial,
    required this.date,
    required this.shift,
    required this.groups,
    required this.station,
    required this.section,
  });

  final String modelSerial;
  final String date;
  final String shift;
  final List<String> groups;
  final String station;
  final String section;

  @override
  List<Object?> get props => <Object?>[
        modelSerial,
        date,
        shift,
        groups,
        station,
        section,
      ];
}
