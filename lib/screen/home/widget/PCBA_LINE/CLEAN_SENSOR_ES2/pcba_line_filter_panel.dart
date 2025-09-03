import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controller/pcba_line_controller.dart';

class PcbaLineFilterPanel extends StatelessWidget {
  final PcbaLineDashboardController controller;

  const PcbaLineFilterPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Obx(() => ElevatedButton.icon(
          onPressed: () => _showDateRangePicker(context),
          icon: const Icon(Icons.calendar_today),
          label: Text(controller.rangeDateTime.value),
        )),
      ],
    );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _getInitialRange(),
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      // Gán giờ mặc định
      final start = DateTime(picked.start.year, picked.start.month, picked.start.day, 7, 30);
      final end = DateTime(picked.end.year, picked.end.month, picked.end.day, 19, 30);

      final rangeStr =
          '${_formatDate(start)} ${_formatTime(start)} - ${_formatDate(end)} ${_formatTime(end)}';
      controller.applyRange(rangeStr);
    }
  }

  DateTimeRange _getInitialRange() {
    final parts = controller.rangeDateTime.value.split(' - ');
    DateTime start = DateTime.now().subtract(const Duration(days: 7));
    DateTime end = DateTime.now();

    if (parts.length == 2) {
      try {
        start = DateFormat('yyyy/MM/dd HH:mm').parseStrict(parts[0]);
        end = DateFormat('yyyy/MM/dd HH:mm').parseStrict(parts[1]);
      } catch (_) {
        // fallback dùng giờ mặc định
        start = DateTime(start.year, start.month, start.day, 7, 30);
        end = DateTime(end.year, end.month, end.day, 19, 30);
      }
    } else {
      start = DateTime(start.year, start.month, start.day, 7, 30);
      end = DateTime(end.year, end.month, end.day, 19, 30);
    }

    return DateTimeRange(start: start, end: end);
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}/${_twoDigits(dt.month)}/${_twoDigits(dt.day)}';

  String _formatTime(DateTime dt) =>
      '${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}';

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
