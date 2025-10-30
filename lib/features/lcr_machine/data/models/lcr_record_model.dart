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
        additionalKeys: const [
          'SN',
          'serialNo',
          'SerialNo',
          'serialNumber',
          'SerialNumber',
          'serial number',
          'Serial Number',
          'serial_no',
          'serial #',
          'Serial #',
          'serial#',
          'Serial#',
          'SERIALNO',
          'SERIALNUMBER',
        ],
      ),
      customerPn: _string(
        json,
        'custPn',
        'CustPn',
        additionalKeys: const [
          'customerPn',
          'CustomerPn',
          'CUSTOMERPN',
          'cust pn',
          'Cust Pn',
          'customer pn',
          'Customer Pn',
          'Customer P/N',
          'cust P/N',
          'Cust P/N',
          'customer_pn',
          'cust_pn',
        ],
      ),
      dateCode: _string(
        json,
        'datecode',
        'Datecode',
        additionalKeys: const [
          'DateCode',
          'DATECODE',
          'date code',
          'Date Code',
          'date_code',
          'datecode1',
        ],
      ),
      lotCode: _string(
        json,
        'lotcode',
        'Lotcode',
        additionalKeys: const [
          'LotCode',
          'LOTCODE',
          'lot code',
          'Lot Code',
          'lot_code',
          'lot no',
          'Lot No',
          'lotno',
          'LotNo',
          'LOTNO',
        ],
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
        additionalKeys: const ['QTY', 'quantity', 'Quantity', 'QUANTITY'],
      ),
      extQty: _int(
        json,
        'extqty',
        'Extqty',
        additionalKeys: const [
          'ExtQty',
          'EXTQTY',
          'ext qty',
          'Ext Qty',
          'ext_qty',
        ],
      ),
      description: _string(
        json,
        'description',
        'Description',
        additionalKeys: const ['desc', 'Desc', 'DESC', 'description1'],
      ),
      materialType: _string(
        json,
        'materialtype',
        'Materialtype',
        additionalKeys: const [
          'MaterialType',
          'MATERIALTYPE',
          'material type',
          'Material Type',
          'material_type',
        ],
      ),
      lowSpec: _string(
        json,
        'lowspec',
        'Lowspec',
        additionalKeys: const [
          'LowSpec',
          'LOWSPEC',
          'low spec',
          'Low Spec',
          'low_spec',
        ],
      ),
      highSpec: _string(
        json,
        'highspec',
        'Highspec',
        additionalKeys: const [
          'HighSpec',
          'HIGHSPEC',
          'high spec',
          'High Spec',
          'high_spec',
        ],
      ),
      measureValue: _string(
        json,
        'measurevalue',
        'Measurevalue',
        additionalKeys: const [
          'MeasureValue',
          'MEASUREVALUE',
          'measure value',
          'Measure Value',
          'measure_value',
        ],
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
        additionalKeys: const [
          'EmployeeId',
          'EMPLOYEEID',
          'employee id',
          'Employee Id',
          'employee_id',
        ],
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
            additionalKeys: const [
              'FACTORY',
              'factory name',
              'Factory Name',
              'factory_name',
            ],
          ) ??
          '',
      department: _string(
        json,
        'department',
        'Department',
        additionalKeys: const [
          'DEPARTMENT',
          'department name',
          'Department Name',
          'department_name',
        ],
      ),
      machineNo: _int(
            json,
            'machineno',
            'Machineno',
            additionalKeys: const [
              'MachineNo',
              'MACHINENO',
              'machine no',
              'Machine No',
              'machine_no',
            ],
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
    final normalizedKey = _normalizeKey(key);

    if (json.containsKey(key)) {
      final value = json[key];
      if (_hasContent(value)) {
        return value;
      }
    }

    for (final entry in json.entries) {
      final candidate = entry.key;
      if (_keysMatch(candidate, key, normalizedKey)) {
        final value = entry.value;
        if (_hasContent(value)) {
          return value;
        }
      }
    }
    return null;
  }

  static bool _keysMatch(String candidate, String original, String normalized) {
    if (candidate == original) return true;
    if (candidate.toLowerCase() == original.toLowerCase()) return true;
    return _normalizeKey(candidate) == normalized;
  }

  static bool _hasContent(dynamic value) {
    if (value == null) return false;
    if (value is String) {
      return value.trim().isNotEmpty;
    }
    return true;
  }

  static String _normalizeKey(String key) {
    final buffer = StringBuffer();
    for (final rune in key.runes) {
      final char = String.fromCharCode(rune);
      final lower = char.toLowerCase();
      if (lower.isEmpty) continue;
      final code = lower.codeUnitAt(0);
      final isAlpha = code >= 97 && code <= 122;
      final isDigit = code >= 48 && code <= 57;
      if (isAlpha || isDigit) {
        buffer.write(lower);
      }
    }
    return buffer.toString();
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
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      final withoutCommas = trimmed.replaceAll(',', '');
      final parsedInt = int.tryParse(withoutCommas);
      if (parsedInt != null) return parsedInt;
      final numericMatch = RegExp(r'[+-]?\d+(?:[.,]\d+)?').firstMatch(withoutCommas);
      if (numericMatch != null) {
        final token = numericMatch.group(0)!.replaceAll(',', '');
        final intCandidate = int.tryParse(token);
        if (intCandidate != null) return intCandidate;
        final doubleCandidate = double.tryParse(token);
        if (doubleCandidate != null) return doubleCandidate.toInt();
      }
    }
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
      final lower = value.trim().toLowerCase();
      if (lower == 'true' || lower == '1' || lower == 'pass') return true;
      if (lower == 'false' || lower == '0' || lower == 'fail') return false;
    }
    return null;
  }
}
