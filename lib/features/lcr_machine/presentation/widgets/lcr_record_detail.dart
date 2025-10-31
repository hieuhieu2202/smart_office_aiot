import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/lcr_entities.dart';

class LcrRecordDetail extends StatelessWidget {
  const LcrRecordDetail({
    super.key,
    required this.record,
  });

  final LcrRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = <_DetailEntry>[
      _DetailEntry('DATE TIME', _fmt(record.dateTime)),
      _DetailEntry('SERIAL NUMBER', record.serialNumber ?? '-'),
      _DetailEntry('CUST P/N', record.customerPn ?? '-'),
      _DetailEntry('DATE CODE', record.dateCode ?? '-'),
      _DetailEntry('LOT CODE', record.lotCode ?? '-'),
      _DetailEntry('VENDOR', record.vendor ?? '-'),
      _DetailEntry('VENDOR NO', record.vendorNo ?? '-'),
      _DetailEntry('LOCATION', record.location ?? '-'),
      _DetailEntry('QTY', record.qty?.toString() ?? '-'),
      _DetailEntry('EXT QTY', record.extQty?.toString() ?? '-'),
      _DetailEntry('DESCRIPTION', record.description ?? '-'),
      _DetailEntry('MATERIAL TYPE', record.materialType ?? '-'),
      _DetailEntry('LOW SPEC', record.lowSpec ?? '-'),
      _DetailEntry('HIGH SPEC', record.highSpec ?? '-'),
      _DetailEntry('MEASURE VALUE', record.measureValue ?? '-'),
      _DetailEntry('STATUS', record.status ? 'PASS' : 'FAIL'),
      _DetailEntry('EMPLOYEE ID', record.employeeId ?? '-'),
      _DetailEntry('ID RECORD', record.recordId),
      _DetailEntry('FACTORY', record.factory),
      _DetailEntry('DEPARTMENT', record.department ?? '-'),
      _DetailEntry('MACHINE NO', record.machineNo.toString()),
      _DetailEntry('WORK DATE', record.workDate),
      _DetailEntry('WORK SECTION', record.workSection.toString()),
      _DetailEntry('CLASS', record.className == 'D' ? 'DAY' : record.className),
      _DetailEntry('CLASS DATE', record.classDate),
      _DetailEntry('ID', record.id.toString()),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF03132D).withOpacity(0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;

          return _DetailTable(
            entries: entries,
            theme: theme,
            viewportWidth: viewportWidth,
          );
        },
      ),
    );
  }

  String _fmt(DateTime dateTime) {
    return '${dateTime.year}-${_pad(dateTime.month)}-${_pad(dateTime.day)} ${_pad(dateTime.hour)}:${_pad(dateTime.minute)}:${_pad(dateTime.second)}';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}

class _DetailEntry {
  const _DetailEntry(this.label, this.value);

  final String label;
  final String value;
}

class _DetailTable extends StatelessWidget {
  const _DetailTable({
    required this.entries,
    required this.theme,
    required this.viewportWidth,
  });

  final List<_DetailEntry> entries;
  final ThemeData theme;
  final double viewportWidth;

  @override
  Widget build(BuildContext context) {
    const double columnSpacing = 12;
    final double minColumnWidth = math.max(120, viewportWidth / 3);

    final widths = <double>[];
    for (final entry in entries) {
      widths.add(_preferredColumnWidth(entry.label, minColumnWidth));
    }

    final totalWidth = widths.fold<double>(0, (sum, width) => sum + width) +
        columnSpacing * (entries.length - 1);

    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      color: Colors.cyanAccent,
      fontWeight: FontWeight.w700,
      fontSize: 12.5,
      letterSpacing: 0.7,
    );

    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 13.5,
      letterSpacing: 0.3,
      height: 1.3,
    );

    final table = Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: {
        for (var i = 0; i < widths.length; i++) i: FixedColumnWidth(widths[i]),
      },
      border: TableBorder(
        top: BorderSide(color: Colors.white.withOpacity(0.18)),
        bottom: BorderSide(color: Colors.white.withOpacity(0.18)),
        left: BorderSide(color: Colors.white.withOpacity(0.14)),
        right: BorderSide(color: Colors.white.withOpacity(0.14)),
        horizontalInside: BorderSide(color: Colors.white.withOpacity(0.14)),
        verticalInside: BorderSide(color: Colors.white.withOpacity(0.14)),
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
          ),
          children: [
            for (var i = 0; i < entries.length; i++)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: columnSpacing,
                  vertical: 14,
                ),
                child: Text(
                  entries[i].label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: headerStyle,
                ),
              ),
          ],
        ),
        TableRow(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
          ),
          children: [
            for (var i = 0; i < entries.length; i++)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: columnSpacing,
                  vertical: 16,
                ),
                child: _ValueCell(
                  entry: entries[i],
                  style: valueStyle,
                ),
              ),
          ],
        ),
      ],
    );

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: math.max(viewportWidth, totalWidth),
          child: table,
        ),
      ),
    );
  }

  double _preferredColumnWidth(String label, double minColumnWidth) {
    switch (label) {
      case 'DATE TIME':
      case 'CLASS DATE':
      case 'WORK DATE':
        return math.max(minColumnWidth, 190);
      case 'DESCRIPTION':
        return math.max(minColumnWidth, 260);
      case 'MEASURE VALUE':
      case 'LOW SPEC':
      case 'HIGH SPEC':
        return math.max(minColumnWidth, 180);
      case 'SERIAL NUMBER':
      case 'ID RECORD':
        return math.max(minColumnWidth, 200);
      default:
        return math.max(minColumnWidth, 150);
    }
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({
    required this.entry,
    required this.style,
  });

  final _DetailEntry entry;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final isStatus = entry.label == 'STATUS';
    final statusColor = entry.value.toUpperCase() == 'FAIL'
        ? Colors.redAccent
        : Colors.cyanAccent;

    return Text(
      entry.value,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      softWrap: true,
      style: (style ?? const TextStyle()).copyWith(
        color: isStatus ? statusColor : style?.color,
      ),
    );
  }
}
