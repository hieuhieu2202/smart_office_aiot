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
    final dateTimeRaw = _firstNonNull<dynamic>(
      json,
      const ['dateTime', 'DateTime'],
    );
    final dateTime = dateTimeRaw is String
        ? DateTime.tryParse(dateTimeRaw)
        : dateTimeRaw is DateTime
            ? dateTimeRaw
            : null;

    final workDate = _string(json, 'workDate', 'WorkDate');
    final workSection = _int(json, 'workSection', 'WorkSection');
    final className = _string(json, 'class', 'Class', additionalKeys: const ['ClassName']);
    final classDate = _string(json, 'classDate', 'ClassDate');

    return LcrRecordModel(
      id: _int(json, 'id', 'Id') ?? 0,
      dateTime: dateTime ?? DateTime.fromMillisecondsSinceEpoch(0),
      workDate: workDate ?? '',
      workSection: workSection ?? 0,
      className: className ?? '',
      classDate: classDate ?? '',
      serialNumber: _string(
        json,
        'sn',
        'Sn',
        additionalKeys: const ['SN'],
      ),
      customerPn: _string(
        json,
        'custPn',
        'CustPn',
        additionalKeys: const ['customerPn', 'CustomerPn', 'CUSTOMERPN'],
      ),
      dateCode: _string(
        json,
        'datecode',
        'Datecode',
        additionalKeys: const ['DateCode', 'DATECODE'],
      ),
      lotCode: _string(
        json,
        'lotcode',
        'Lotcode',
        additionalKeys: const ['LotCode', 'LOTCODE'],
      ),
      vendor: _string(json, 'vendor', 'Vendor'),
      vendorNo: _string(
        json,
        'vendorNo',
        'Vendorno',
        additionalKeys: const ['VendorNo', 'VENDORNO'],
      ),
      location: _string(json, 'location', 'Location'),
      qty: _int(
        json,
        'qty',
        'Qty',
        additionalKeys: const ['QTY'],
      ),
      extQty: _int(
        json,
        'extqty',
        'Extqty',
        additionalKeys: const ['ExtQty', 'EXTQTY'],
      ),
      description: _string(json, 'description', 'Description'),
      materialType: _string(
        json,
        'materialtype',
        'Materialtype',
        additionalKeys: const ['MaterialType', 'MATERIALTYPE'],
      ),
      lowSpec: _string(
        json,
        'lowspec',
        'Lowspec',
        additionalKeys: const ['LowSpec', 'LOWSPEC'],
      ),
      highSpec: _string(
        json,
        'highspec',
        'Highspec',
        additionalKeys: const ['HighSpec', 'HIGHSPEC'],
      ),
      measureValue: _string(
        json,
        'measurevalue',
        'Measurevalue',
        additionalKeys: const ['MeasureValue', 'MEASUREVALUE'],
      ),
      status: _bool(
            json,
            'status',
            'Status',
            additionalKeys: const ['STATUS'],
          ) ??
          false,
      employeeId: _string(
        json,
        'employeeid',
        'Employeeid',
        additionalKeys: const ['EmployeeId', 'EMPLOYEEID'],
      ),
      recordId: _string(
            json,
            'idrecord',
            'Idrecord',
            additionalKeys: const ['IdRecord', 'IDRECORD'],
          ) ??
          '',
      factory: _string(
            json,
            'factory',
            'Factory',
            additionalKeys: const ['FACTORY'],
          ) ??
          '',
      department: _string(
        json,
        'department',
        'Department',
        additionalKeys: const ['DEPARTMENT'],
      ),
      machineNo: _int(
            json,
            'machineno',
            'Machineno',
            additionalKeys: const ['MachineNo', 'MACHINENO'],
          ) ??
          0,
    );
  }

  static T? _firstNonNull<T>(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = _read(json, key);
      if (value != null) {
        return value as T;
      }
    }
    return null;
  }

  static dynamic _read(Map<String, dynamic> json, String key) {
    if (json.containsKey(key)) {
      final value = json[key];
      if (value != null && !(value is String && value.trim().isEmpty)) {
        return value;
      }
    }
    final lowerKey = key.toLowerCase();
    for (final entry in json.entries) {
      if (entry.key.toLowerCase() == lowerKey) {
        final value = entry.value;
        if (value != null && !(value is String && value.trim().isEmpty)) {
          return value;
        }
      }
    }
    return null;
  }

  static String? _string(
    Map<String, dynamic> json,
    String k1,
    String k2, {
    List<String> additionalKeys = const [],
  }) {
    final dynamic value = _firstNonNull<dynamic>(
      json,
      <String>[k1, k2, ...additionalKeys],
    );
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    final converted = value.toString().trim();
    return converted.isEmpty ? null : converted;
  }

  static int? _int(
    Map<String, dynamic> json,
    String k1,
    String k2, {
    List<String> additionalKeys = const [],
  }) {
    final dynamic value = _firstNonNull<dynamic>(
      json,
      <String>[k1, k2, ...additionalKeys],
    );
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static bool? _bool(
    Map<String, dynamic> json,
    String k1,
    String k2, {
    List<String> additionalKeys = const [],
  }) {
    final dynamic value = _firstNonNull<dynamic>(
      json,
      <String>[k1, k2, ...additionalKeys],
    );
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
