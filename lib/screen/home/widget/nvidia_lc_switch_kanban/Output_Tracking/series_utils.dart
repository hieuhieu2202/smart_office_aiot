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

  return ui.Gradient.linear(
    rect.topLeft,
    rect.bottomRight,
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
