import '../../domain/entities/lcr_entities.dart';

class LcrDepartmentModel extends LcrDepartment {
  LcrDepartmentModel({required super.name, required super.machines});

  factory LcrDepartmentModel.fromJson(Map<String, dynamic> json) {
    final name = _string(json, 'name', 'Name') ?? '';
    final machinesRaw = json['machines'] ?? json['Machines'];
    final List<int> machines;
    if (machinesRaw is List) {
      machines = machinesRaw
          .map((e) => e is int
              ? e
              : e is num
                  ? e.toInt()
                  : int.tryParse(e.toString()) ?? 0)
          .toList();
    } else {
      machines = const <int>[];
    }
    return LcrDepartmentModel(name: name, machines: machines);
  }

  static String? _string(Map<String, dynamic> json, String k1, String k2) {
    final dynamic v = json[k1] ?? json[k2];
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }
}

class LcrFactoryModel extends LcrFactory {
  LcrFactoryModel({required super.name, required super.departments});

  factory LcrFactoryModel.fromJson(Map<String, dynamic> json) {
    final departmentsRaw = json['departments'] ?? json['Departments'];
    final List<LcrDepartment> departments;
    if (departmentsRaw is List) {
      departments = departmentsRaw
          .whereType<Map<String, dynamic>>()
          .map(LcrDepartmentModel.fromJson)
          .toList();
    } else {
      departments = const <LcrDepartment>[];
    }
    return LcrFactoryModel(
      name: LcrDepartmentModel._string(json, 'name', 'Name') ?? '',
      departments: departments,
    );
  }
}
