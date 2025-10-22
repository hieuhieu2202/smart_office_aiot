import 'dart:math';

List<double> ensureSeries(
  String group,
  Map<String, List<double>> source,
  int expectedLength,
) {
  if (expectedLength <= 0) {
    return const <double>[];
  }

  final values = source[group] ?? const <double>[];
  if (values.length == expectedLength) {
    return values;
  }
  if (values.length > expectedLength) {
    return List<double>.from(values.take(expectedLength));
  }
  return <double>[
    ...values,
    ...List<double>.filled(max(0, expectedLength - values.length), 0),
  ];
}

String formatHourRange(String value) {
  final raw = value.trim();
  if (raw.contains(':')) {
    return raw;
  }

  final hour = int.tryParse(raw);
  if (hour == null) {
    return raw;
  }

  final endHour = hour % 24;
  final startHour = (hour - 1) < 0 ? 23 : hour - 1;
  return '${_padHour(startHour)}:30 - ${_padHour(endHour)}:30';
}

String _padHour(int value) => value.toString().padLeft(2, '0');
