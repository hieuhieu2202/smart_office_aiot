import 'dart:ui' as ui;

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

Shader build3dColumnShader(ui.Rect rect, Color baseColor) {
  if (rect.width == 0 || rect.height == 0) {
    final point = rect.topLeft;
    return ui.Gradient.linear(
      point,
      point.translate(0, 1),
      [baseColor, baseColor],
    );
  }

  final highlight = _lighten(baseColor, 0.38);
  final midHighlight = _lighten(baseColor, 0.18);
  final shadow = _darken(baseColor, 0.22);
  final deepShadow = _darken(baseColor, 0.42);

  final topCenter = ui.Offset(rect.left + rect.width / 2, rect.top);
  final bottomCenter = ui.Offset(rect.left + rect.width / 2, rect.bottom);

  return ui.Gradient.linear(
    topCenter,
    bottomCenter,
    [highlight, midHighlight, baseColor, shadow, deepShadow],
    const [0.0, 0.32, 0.6, 0.82, 1.0],
  );
}

Shader build3dLineShader(ui.Rect rect, Color baseColor) {
  if (rect.width == 0 || rect.height == 0) {
    final point = rect.topLeft;
    return ui.Gradient.linear(
      point,
      point.translate(0, 1),
      [baseColor, baseColor],
    );
  }

  final top = _lighten(baseColor, 0.25);
  final mid = baseColor;
  final bottom = _darken(baseColor, 0.25);

  return ui.Gradient.linear(
    ui.Offset(rect.left, rect.top),
    ui.Offset(rect.left, rect.bottom),
    [top, mid, bottom],
    const [0.0, 0.55, 1.0],
  );
}

Color _lighten(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
  return hsl.withLightness(lightness).toColor();
}

Color _darken(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
  return hsl.withLightness(lightness).toColor();
}
