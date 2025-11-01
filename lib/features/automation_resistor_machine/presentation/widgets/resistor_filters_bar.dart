import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ResistorFiltersBar extends StatelessWidget {
  const ResistorFiltersBar({
    super.key,
    required this.machineOptions,
    required this.selectedMachine,
    required this.onMachineChanged,
    required this.selectedShift,
    required this.onShiftChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.dateRange,
    required this.onSelectDate,
  });

  final List<String> machineOptions;
  final String selectedMachine;
  final ValueChanged<String> onMachineChanged;
  final String selectedShift;
  final ValueChanged<String> onShiftChanged;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;
  final DateTimeRange dateRange;
  final VoidCallback onSelectDate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isCompact = constraints.maxWidth < 900;
      final content = <Widget>[
        _DropdownTile(
          label: 'Machine',
          value: selectedMachine,
          options: machineOptions,
          onChanged: onMachineChanged,
        ),
        _SegmentedTile(
          label: 'Shift',
          value: selectedShift,
          onChanged: onShiftChanged,
          options: const ['D', 'N'],
        ),
        _SegmentedTile(
          label: 'Status',
          value: selectedStatus,
          onChanged: onStatusChanged,
          options: const ['ALL', 'PASS', 'FAIL'],
        ),
        _DateTile(
          label: 'Date range',
          range: dateRange,
          onTap: onSelectDate,
        ),
      ];

      if (isCompact) {
        return Wrap(
          runSpacing: 12,
          spacing: 12,
          children: content,
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: content
            .map((widget) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: widget,
                  ),
                ))
            .toList(),
      );
    });
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
        items: options
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: const TextStyle(color: Colors.white)),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _SegmentedTile extends StatelessWidget {
  const _SegmentedTile({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.options,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return _TileContainer(
      label: label,
      child: ToggleButtons(
        borderRadius: BorderRadius.circular(12),
        borderColor: Colors.white24,
        selectedBorderColor: Colors.cyanAccent,
        fillColor: Colors.cyanAccent.withOpacity(0.1),
        selectedColor: Colors.cyanAccent,
        color: Colors.white70,
        isSelected: options.map((e) => e == value).toList(),
        onPressed: (index) => onChanged(options[index]),
        children: options
            .map(
              (option) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(option),
              ),
            )
            .toList(),
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _TileContainer(
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF03132D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: child,
        ),
      ],
    );
  }
}
