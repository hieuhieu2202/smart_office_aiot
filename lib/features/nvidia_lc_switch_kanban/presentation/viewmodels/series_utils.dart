import 'package:flutter/material.dart';

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

int? findActiveHourIndex(
  List<String> sections,
  DateTime selectedDate, {
  DateTime? now,
}) {
  if (sections.isEmpty) return null;

  final List<_SectionWindow> windows =
      _buildSectionTimeline(sections, selectedDate);
  if (windows.isEmpty) return null;

  final DateTime probe = now ?? DateTime.now();
  final _SectionWindow first = windows.first;
  final _SectionWindow last = windows.last;

  if (probe.isBefore(first.start) || probe.isAfter(last.end)) {
    return null;
  }

  for (int i = 0; i < windows.length; i++) {
    final _SectionWindow window = windows[i];
    final bool startsOrBefore =
        !probe.isBefore(window.start); // probe >= start
    final bool beforeEnd = probe.isBefore(window.end);
    if (startsOrBefore && beforeEnd) {
      return i;
    }
  }

  return null;
}

class _SectionWindow {
  const _SectionWindow({
    required this.section,
    required this.start,
    required this.end,
  });

  final String section;
  final DateTime start;
  final DateTime end;
}

List<_SectionWindow> _buildSectionTimeline(
  List<String> sections,
  DateTime selectedDate,
) {
  final List<_SectionWindow> result = <_SectionWindow>[];
  if (sections.isEmpty) return result;

  final DateTime baseDay =
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  DateTime? lastEnd;

  for (final String raw in sections) {
    final int? parsed = int.tryParse(raw.trim());
    if (parsed == null) continue;

    final int startHour = ((parsed - 1) % 24 + 24) % 24;
    final int endHour = parsed % 24;

    DateTime start =
        DateTime(baseDay.year, baseDay.month, baseDay.day, startHour, 30);
    DateTime end =
        DateTime(baseDay.year, baseDay.month, baseDay.day, endHour, 30);

    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }

    if (lastEnd != null) {
      while (start.isBefore(lastEnd)) {
        start = start.add(const Duration(days: 1));
        end = end.add(const Duration(days: 1));
      }
    }

    final window =
        _SectionWindow(section: raw, start: start, end: end);
    result.add(window);
    lastEnd = window.end;
  }

  return result;
}

