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
      _DetailEntry('ID', record.id.toString()),
      _DetailEntry('DATE TIME', _fmt(record.dateTime)),
      _DetailEntry('WORK DATE', record.workDate),
      _DetailEntry('WORK SECTION', record.workSection.toString()),
      _DetailEntry('CLASS', record.className == 'D' ? 'DAY' : record.className),
      _DetailEntry('CLASS DATE', record.classDate),
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
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF03132D).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;

          return _DetailGrid(
            entries: entries,
            theme: theme,
            maxWidth: viewportWidth,
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

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({
    required this.entries,
    required this.theme,
    required this.maxWidth,
  });

  final List<_DetailEntry> entries;
  final ThemeData theme;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    const crossAxisSpacing = 14.0;
    const runSpacing = 12.0;
    const baseAspectRatio = 2.25;
    const minTileHeight = 96.0;

    final double availableWidth = maxWidth.isFinite && maxWidth > 0
        ? maxWidth
        : MediaQuery.of(context).size.width;

    final int crossAxisCount = availableWidth >= 1160
        ? 5
        : availableWidth >= 940
            ? 4
            : 3;

    final spacingWidth = crossAxisSpacing * (crossAxisCount - 1);
    final tileWidth = (availableWidth - spacingWidth) / crossAxisCount;
    final idealTileHeight = tileWidth / baseAspectRatio;
    final tileHeight = idealTileHeight < minTileHeight ? minTileHeight : idealTileHeight;
    final bool compactTile = tileWidth < 150;
    final int? valueMaxLines = compactTile ? 6 : null;
    final labelFontSize = compactTile ? 11.0 : 12.5;
    final valueFontSize = compactTile ? 13.0 : 15.0;
    final verticalGap = compactTile ? 4.0 : 6.0;

    return SizedBox(
      width: availableWidth,
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        child: Wrap(
          spacing: crossAxisSpacing,
          runSpacing: runSpacing,
          children: [
            for (final entry in entries)
              SizedBox(
                width: tileWidth,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: tileHeight),
                  child: _DetailTile(
                    entry: entry,
                    theme: theme,
                    maxLines: valueMaxLines,
                    labelFontSize: labelFontSize,
                    valueFontSize: valueFontSize,
                    verticalGap: verticalGap,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.entry,
    required this.theme,
    required this.maxLines,
    required this.labelFontSize,
    required this.valueFontSize,
    required this.verticalGap,
  });

  final _DetailEntry entry;
  final ThemeData theme;
  final int? maxLines;
  final double labelFontSize;
  final double valueFontSize;
  final double verticalGap;

  @override
  Widget build(BuildContext context) {
    final isImportant = entry.label == 'STATUS' || entry.label == 'SERIAL NUMBER';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
        color: isImportant
            ? Colors.cyan.withOpacity(0.15)
            : Colors.white.withOpacity(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              entry.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                fontSize: labelFontSize,
                height: 1.1,
              ),
            ),
          ),
          SizedBox(height: verticalGap),
          Text(
            entry.value,
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.visible,
            softWrap: true,
            style: theme.textTheme.titleSmall?.copyWith(
              color: isImportant
                  ? (entry.label == 'STATUS' && entry.value == 'FAIL'
                      ? Colors.redAccent
                      : Colors.cyanAccent)
                  : Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              fontSize: valueFontSize,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
