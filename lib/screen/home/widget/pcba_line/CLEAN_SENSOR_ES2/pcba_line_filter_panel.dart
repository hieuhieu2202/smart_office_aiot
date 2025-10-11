import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../../controller/pcba_line_controller.dart';

class PcbaLineFilterPanel extends StatelessWidget {
  final PcbaLineDashboardController controller;
  const PcbaLineFilterPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Filter',
      icon: const Icon(Icons.filter_alt),
      onPressed: () => _openSlidePanel(context),
    );
  }

  // OPEN SLIDE PANEL
  Future<void> _openSlidePanel(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fFull = DateFormat('yyyy/MM/dd HH:mm');

    DateTime start, end;
    DateTime now = DateTime.now();
    DateTime endDay = DateTime(now.year, now.month, now.day);
    end = DateTime(endDay.year, endDay.month, endDay.day, 19, 30);
    start = DateTime(endDay.year, endDay.month, endDay.day - 7, 7, 30);

    final parts = controller.rangeDateTime.value.split(' - ');
    if (parts.length == 2) {
      try {
        start = DateFormat('yyyy/MM/dd HH:mm').parseStrict(parts[0]);
        end   = DateFormat('yyyy/MM/dd HH:mm').parseStrict(parts[1]);
      } catch (_) {}
    }

    await showGeneralDialog(
      context: context,
      barrierLabel: 'Filter',
      barrierColor: Colors.black26,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final offset = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));

        return SlideTransition(
          position: offset,
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              elevation: 10,
              borderRadius: BorderRadius.circular(12),
              child: _PcbaFilterForm(
                startInit: start,
                endInit: end,
                isDark: isDark,
                onCancel: () => Navigator.of(ctx).pop(),
                onApply: (s, e) {
                  controller.applyRange('${fFull.format(s)} - ${fFull.format(e)}');
                  Navigator.of(ctx).pop();
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PcbaFilterForm extends StatefulWidget {
  final DateTime startInit;
  final DateTime endInit;
  final bool isDark;
  final void Function() onCancel;
  final void Function(DateTime start, DateTime end) onApply;

  const _PcbaFilterForm({
    required this.startInit,
    required this.endInit,
    required this.isDark,
    required this.onCancel,
    required this.onApply,
  });

  @override
  State<_PcbaFilterForm> createState() => _PcbaFilterFormState();
}

class _PcbaFilterFormState extends State<_PcbaFilterForm> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _start = widget.startInit;
    _end   = widget.endInit;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final fFull = DateFormat('yyyy/MM/dd HH:mm');

    return Container(
      width: 250,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232F34) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.16), blurRadius: 20)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // close
          Row(
            children: [
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, size: 28), onPressed: widget.onCancel),
            ],
          ),
          const SizedBox(height: 16),
          Text('Filter',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 28),

          // From
          const Text('From', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _DateTimePicker(
            date: _start,
            isDark: isDark,
            onChanged: (d) => setState(() {
              _start = d;
              if (_end.isBefore(_start)) {
                _end = DateTime(_start.year, _start.month, _start.day, 19, 30);
              }
            }),
          ),

          const SizedBox(height: 16),

          // To
          const Text('To', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _DateTimePicker(
            date: _end,
            isDark: isDark,
            onChanged: (d) => setState(() {
              _end = d;
              if (_end.isBefore(_start)) {
                _start = DateTime(_end.year, _end.month, _end.day, 7, 30);
              }
            }),
          ),

          const Spacer(),

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.grey[700] : Colors.grey[600],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => widget.onApply(_start, _end),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  final DateTime date;
  final bool isDark;
  final ValueChanged<DateTime> onChanged;

  const _DateTimePicker({
    required this.date,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('yyyy/MM/dd HH:mm');

    return InkWell(
      onTap: () async {
        // Date
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(date.year - 1),
          lastDate: DateTime(date.year + 1),
          builder: (ctx, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark
                  ? const ColorScheme.dark(primary: Colors.blueAccent)
                  : const ColorScheme.light(primary: Colors.blue),
            ),
            child: child!,
          ),
        );
        if (picked == null) return;

        // Time
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(date),
          builder: (ctx, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark
                  ? const ColorScheme.dark(primary: Colors.blueAccent)
                  : const ColorScheme.light(primary: Colors.blue),
            ),
            child: child!,
          ),
        );
        if (pickedTime == null) return;

        onChanged(DateTime(picked.year, picked.month, picked.day, pickedTime.hour, pickedTime.minute));
      },
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 13),
        decoration: BoxDecoration(
          color: isDark ? Colors.blueGrey[900] : Colors.blueGrey[50],
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          format.format(date),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
