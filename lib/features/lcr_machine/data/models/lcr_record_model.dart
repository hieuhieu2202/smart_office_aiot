import '../../domain/entities/lcr_entities.dart';

class LcrRecordModel extends LcrRecord {
  LcrRecordModel({
    required super.id,
    required super.dateTime,
    required super.workDate,
    required super.workSection,
    required super.className,
    required super.classDate,
    required super.serialNumber,
    required super.customerPn,
    required super.dateCode,
    required super.lotCode,
    required super.vendor,
    required super.vendorNo,
    required super.location,
    required super.qty,
    required super.extQty,
    required super.description,
    required super.materialType,
    required super.lowSpec,
    required super.highSpec,
    required super.measureValue,
    required super.status,
    required super.employeeId,
    required super.recordId,
    required super.factory,
    required super.department,
    required super.machineNo,
  });

  factory LcrRecordModel.fromJson(Map<String, dynamic> json) {
    final dateTimeRaw = _firstNonNull<dynamic>(json, 'dateTime', 'DateTime');
    final dateTime = dateTimeRaw is String
        ? DateTime.tryParse(dateTimeRaw)
        : dateTimeRaw is DateTime
            ? dateTimeRaw
            : null;

    final workDate = _string(json, 'workDate', 'WorkDate');
    final workSection = _int(json, 'workSection', 'WorkSection');
    final className = _string(json, 'class', 'Class');
    final classDate = _string(json, 'classDate', 'ClassDate');

    return LcrRecordModel(
      id: _int(json, 'id', 'Id') ?? 0,
      dateTime: dateTime ?? DateTime.fromMillisecondsSinceEpoch(0),
      workDate: workDate ?? '',
      workSection: workSection ?? 0,
      className: className ?? '',
      classDate: classDate ?? '',
      serialNumber: _string(json, 'sn', 'Sn'),
      customerPn: _string(json, 'custPn', 'CustPn'),
      dateCode: _string(json, 'datecode', 'Datecode'),
      lotCode: _string(json, 'lotcode', 'Lotcode'),
      vendor: _string(json, 'vendor', 'Vendor'),
      vendorNo: _string(json, 'vendorNo', 'Vendorno'),
      location: _string(json, 'location', 'Location'),
      qty: _int(json, 'qty', 'Qty'),
      extQty: _int(json, 'extqty', 'Extqty'),
      description: _string(json, 'description', 'Description'),
      materialType: _string(json, 'materialtype', 'Materialtype'),
      lowSpec: _string(json, 'lowspec', 'Lowspec'),
      highSpec: _string(json, 'highspec', 'Highspec'),
      measureValue: _string(json, 'measurevalue', 'Measurevalue'),
      status: _bool(json, 'status', 'Status') ?? false,
      employeeId: _string(json, 'employeeid', 'Employeeid'),
      recordId: _string(json, 'idrecord', 'Idrecord') ?? '',
      factory: _string(json, 'factory', 'Factory') ?? '',
      department: _string(json, 'department', 'Department'),
      machineNo: _int(json, 'machineno', 'Machineno') ?? 0,
    );
  }

  static T? _firstNonNull<T>(Map<String, dynamic> json, String k1, String k2) {
    final dynamic v1 = json[k1];
    if (v1 != null) return v1 as T;
    final dynamic v2 = json[k2];
    if (v2 != null) return v2 as T;
    return null;
  }

  static String? _string(Map<String, dynamic> json, String k1, String k2) {
    final dynamic value = _firstNonNull<dynamic>(json, k1, k2);
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static int? _int(Map<String, dynamic> json, String k1, String k2) {
    final dynamic value = _firstNonNull<dynamic>(json, k1, k2);
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool? _bool(Map<String, dynamic> json, String k1, String k2) {
    final dynamic value = _firstNonNull<dynamic>(json, k1, k2);
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1' || lower == 'pass') return true;
      if (lower == 'false' || lower == '0' || lower == 'fail') return false;
    }
    return null;
  }
}
