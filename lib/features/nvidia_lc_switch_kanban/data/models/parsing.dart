import '../../domain/entities/kanban_entities.dart';

int readInt(Map<String, dynamic> source, List<String> keys) {
  final dynamic value = valueFor(source, keys);
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim()) ?? 0;
}

double readDouble(Map<String, dynamic> source, List<String> keys) {
  final dynamic value = valueFor(source, keys);
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim()) ?? 0.0;
}

String readString(Map<String, dynamic> source, List<String> keys) {
  final dynamic value = valueFor(source, keys);
  return value == null ? '' : value.toString().trim();
}

List<double> readNumList(Map<String, dynamic> source, List<String> keys) {
  final dynamic value = valueFor(source, keys);
  if (value is! List) return const <double>[];
  return value
      .map((dynamic e) =>
          e is num ? e.toDouble() : double.tryParse(e.toString()) ?? 0.0)
      .toList();
}

dynamic valueFor(Map<String, dynamic> source, List<String> keys) {
  for (final String key in keys) {
    if (source.containsKey(key)) {
      final dynamic v = source[key];
      if (v is String && v.trim().isEmpty) continue;
      if (v != null) return v;
    }
  }
  final Map<String, dynamic> lower = {
    for (final MapEntry<String, dynamic> entry in source.entries)
      entry.key.toLowerCase(): entry.value,
  };
  for (final String key in keys) {
    final dynamic v = lower[key.toLowerCase()];
    if (v is String && v.trim().isEmpty) continue;
    if (v != null) return v;
  }
  return null;
}

List<ErrorDetailEntity> readErrorDetails(List<Map<String, dynamic>> raw) {
  return raw.map(ErrorDetailModel.fromJson).toList();
}

List<TesterDetailEntity> readTesterDetails(List<Map<String, dynamic>> raw) {
  return raw.map(TesterDetailModel.fromJson).toList();
}

class ErrorDetailModel extends ErrorDetailEntity {
  ErrorDetailModel({required String code, required int failQty})
      : super(code: code, failQty: failQty);

  factory ErrorDetailModel.fromJson(Map<String, dynamic> json) {
    final String code = valueFor(
              json,
              const ['ERROR_CODE', 'erroR_CODE', 'errorCode', 'code'],
            )
            ?.toString() ??
        '';
    final dynamic qtyValue = valueFor(
      json,
      const ['FAIL_QTY', 'failQty', 'faiL_QTY', 'qty'],
    );

    int readQty() {
      if (qtyValue == null) return 0;
      if (qtyValue is num) return qtyValue.round();
      final String text = qtyValue.toString().trim();
      if (text.isEmpty) return 0;
      final int? parsedInt = int.tryParse(text);
      if (parsedInt != null) return parsedInt;
      final double? parsedDouble = double.tryParse(text);
      if (parsedDouble != null) return parsedDouble.round();
      return 0;
    }

    return ErrorDetailModel(
      code: code,
      failQty: readQty(),
    );
  }
}

class TesterDetailModel extends TesterDetailEntity {
  TesterDetailModel({required String stationName, required int failQty})
      : super(stationName: stationName, failQty: failQty);

  factory TesterDetailModel.fromJson(Map<String, dynamic> json) {
    final String station = valueFor(
              json,
              const ['STATION_NAME', 'statioN_NAME', 'stationName', 'station'],
            )
            ?.toString() ??
        '';
    final dynamic qtyValue = valueFor(
      json,
      const ['FAIL_QTY', 'failQty', 'faiL_QTY', 'qty'],
    );

    int readQty() {
      if (qtyValue == null) return 0;
      if (qtyValue is num) return qtyValue.round();
      final String text = qtyValue.toString().trim();
      if (text.isEmpty) return 0;
      final int? parsedInt = int.tryParse(text);
      if (parsedInt != null) return parsedInt;
      final double? parsedDouble = double.tryParse(text);
      if (parsedDouble != null) return parsedDouble.round();
      return 0;
    }

    return TesterDetailModel(
      stationName: station,
      failQty: readQty(),
    );
  }
}
