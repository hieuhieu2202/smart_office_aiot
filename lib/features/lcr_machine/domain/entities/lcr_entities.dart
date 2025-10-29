import 'package:equatable/equatable.dart';

class LcrRequest extends Equatable {
  const LcrRequest({
    required this.factory,
    required this.department,
    required this.machineNo,
    required this.dateRange,
    required this.status,
  });

  final String factory;
  final String department;
  final String machineNo;
  final String dateRange;
  final String status;

  LcrRequest copyWith({
    String? factory,
    String? department,
    String? machineNo,
    String? dateRange,
    String? status,
  }) {
    return LcrRequest(
      factory: factory ?? this.factory,
      department: department ?? this.department,
      machineNo: machineNo ?? this.machineNo,
      dateRange: dateRange ?? this.dateRange,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toBody() {
    return <String, dynamic>{
      'factory': factory,
      'department': department,
      'machineNo': machineNo,
      'dateRange': dateRange,
      'status': status,
    };
  }

  @override
  List<Object?> get props => <Object?>[
        factory,
        department,
        machineNo,
        dateRange,
        status,
      ];
}

class LcrFactory extends Equatable {
  const LcrFactory({
    required this.name,
    required this.departments,
  });

  final String name;
  final List<LcrDepartment> departments;

  @override
  List<Object?> get props => <Object?>[name, departments];
}

class LcrDepartment extends Equatable {
  const LcrDepartment({
    required this.name,
    required this.machines,
  });

  final String name;
  final List<int> machines;

  @override
  List<Object?> get props => <Object?>[name, machines];
}

class LcrRecord extends Equatable {
  const LcrRecord({
    required this.id,
    required this.dateTime,
    required this.workDate,
    required this.workSection,
    required this.className,
    required this.classDate,
    required this.serialNumber,
    required this.customerPn,
    required this.dateCode,
    required this.lotCode,
    required this.vendor,
    required this.vendorNo,
    required this.location,
    required this.qty,
    required this.extQty,
    required this.description,
    required this.materialType,
    required this.lowSpec,
    required this.highSpec,
    required this.measureValue,
    required this.status,
    required this.employeeId,
    required this.recordId,
    required this.factory,
    required this.department,
    required this.machineNo,
  });

  final int id;
  final DateTime dateTime;
  final String workDate;
  final int workSection;
  final String className;
  final String classDate;
  final String? serialNumber;
  final String? customerPn;
  final String? dateCode;
  final String? lotCode;
  final String? vendor;
  final String? vendorNo;
  final String? location;
  final int? qty;
  final int? extQty;
  final String? description;
  final String? materialType;
  final String? lowSpec;
  final String? highSpec;
  final String? measureValue;
  final bool status;
  final String? employeeId;
  final String recordId;
  final String factory;
  final String? department;
  final int machineNo;

  bool get isPass => status;

  @override
  List<Object?> get props => <Object?>[
        id,
        dateTime,
        workDate,
        workSection,
        className,
        classDate,
        serialNumber,
        customerPn,
        dateCode,
        lotCode,
        vendor,
        vendorNo,
        location,
        qty,
        extQty,
        description,
        materialType,
        lowSpec,
        highSpec,
        measureValue,
        status,
        employeeId,
        recordId,
        factory,
        department,
        machineNo,
      ];
}

class LcrOverview extends Equatable {
  const LcrOverview({
    required this.total,
    required this.pass,
    required this.fail,
    required this.yieldRate,
  });

  final int total;
  final int pass;
  final int fail;
  final double yieldRate;

  factory LcrOverview.fromRecords(List<LcrRecord> records) {
    final total = records.length;
    final pass = records.where((r) => r.status).length;
    final fail = total - pass;
    final yr = total == 0 ? 0 : pass / total * 100;
    return LcrOverview(
      total: total,
      pass: pass,
      fail: fail,
      yieldRate: double.parse(yr.toStringAsFixed(2)),
    );
  }

  @override
  List<Object?> get props => <Object?>[total, pass, fail, yieldRate];
}
