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
