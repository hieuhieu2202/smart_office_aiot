import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ResistorFiltersBar extends StatelessWidget {
  const ResistorFiltersBar({
    super.key,
    required this.machineOptions,
    required this.selectedMachine,
    required this.onMachineChanged,
    required this.shiftOptions,
    required this.selectedShift,
    required this.onShiftChanged,
    required this.statusOptions,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.dateRange,
    required this.onSelectDate,
  });

  final List<String> machineOptions;
  final String selectedMachine;
  final ValueChanged<String> onMachineChanged;
  final List<String> shiftOptions;
  final String selectedShift;
  final ValueChanged<String> onShiftChanged;
  final List<String> statusOptions;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;
  final DateTimeRange dateRange;
  final Future<void> Function() onSelectDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DateTile(
          label: 'Date range',
          range: dateRange,
          onTap: () async {
            await onSelectDate();
          },
        ),
        const SizedBox(height: 16),
        _DropdownTile(
          label: 'Machine',
          value: selectedMachine,
          options: machineOptions,
          onChanged: onMachineChanged,
        ),
        const SizedBox(height: 16),
        _DropdownTile(
          label: 'Shift',
          value: selectedShift,
          options: shiftOptions,
          onChanged: onShiftChanged,
        ),
        const SizedBox(height: 16),
        _DropdownTile(
          label: 'Status',
          value: selectedStatus,
          options: statusOptions,
          onChanged: onStatusChanged,
        ),
      ],
    );
  }
}

class _DropdownTile extends StatelessWidget {
  const _DropdownTile({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _TileContainer(
      label: label,
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: const Color(0xFF03132D),
        decoration: const InputDecoration.collapsed(hintText: ''),
        isExpanded: true,
        iconEnabledColor: Colors.cyanAccent,
        items: options
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: const TextStyle(color: Colors.white)),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.range,
    required this.onTap,
  });

  final String label;
  final DateTimeRange range;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return _TileContainer(
      label: label,
      child: InkWell(
        onTap: () async {
          await onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              const Icon(Icons.calendar_today, color: Colors.cyanAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _formatRange(range),
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRange(DateTimeRange range) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
  }
}

class _TileContainer extends StatelessWidget {
  const _TileContainer({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF03132D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: child,
        ),
      ],
    );
  }
}
