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
          const crossAxisCount = 2;
          const crossAxisSpacing = 16.0;
          const baseAspectRatio = 3.4;
          const minTileHeight = 92.0;

          final availableWidth = constraints.maxWidth;
          final tileWidth = (availableWidth - crossAxisSpacing) / crossAxisCount;
          final idealTileHeight = tileWidth / baseAspectRatio;
          final tileHeight = idealTileHeight < minTileHeight ? minTileHeight : idealTileHeight;
          final childAspectRatio = tileWidth / tileHeight;

          return GridView.builder(
            itemCount: entries.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: 12,
            ),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _DetailTile(entry: entry, theme: theme);
            },
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

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.entry, required this.theme});

  final _DetailEntry entry;
  final ThemeData theme;

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
          Text(
            entry.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white60,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: isImportant
                  ? (entry.label == 'STATUS' && entry.value == 'FAIL'
                      ? Colors.redAccent
                      : Colors.cyanAccent)
                  : Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
