import 'package:flutter/material.dart';

import '../../domain/entities/te_retest_rate.dart';

class TERetestRateTable extends StatelessWidget {
  const TERetestRateTable({
    super.key,
    required this.detail,
    required this.formattedDates,
    this.onCellTap,
    this.onGroupTap,
  });

  final TERetestDetailEntity detail;
  final List<String> formattedDates;
  final ValueChanged<TERetestCellDetail>? onCellTap;
  final ValueChanged<TERetestGroupDetail>? onGroupTap;

  static const _headerColor = Color(0xFF10263F);
  static const _rowColor = Color(0x15122B42);
  static const _borderColor = Color(0x332BD4F5);
  int get _totalColumns => formattedDates.length * 2;

  @override
  Widget build(BuildContext context) {
    if (!detail.hasData || formattedDates.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final columns = <DataColumn>[
      const DataColumn(label: _HeaderLabel('#')),
      const DataColumn(label: _HeaderLabel('Model Name')),
      const DataColumn(label: _HeaderLabel('Group Name')),
    ];

    for (final date in formattedDates) {
      columns.add(DataColumn(label: _DateHeaderLabel(date: date, shift: 'Day')));
      columns.add(DataColumn(label: _DateHeaderLabel(date: date, shift: 'Night')));
    }

    final rows = <DataRow>[];
    var index = 1;

    for (final row in detail.rows) {
      var firstGroup = true;
      for (final group in row.groupNames) {
        final rr = row.retestRate[group] ?? const <double?>[];
        final input = row.input[group] ?? const <int?>[];
        final firstFail = row.firstFail[group] ?? const <int?>[];
        final retestFail = row.retestFail[group] ?? const <int?>[];
        final pass = row.pass[group] ?? const <int?>[];

        final groupDetails = List<TERetestCellDetail>.generate(
          _totalColumns,
          (i) {
            final dateIndex = i ~/ 2;
            final isDay = i.isEven;
            return TERetestCellDetail(
              modelName: row.modelName,
              groupName: group,
              dateLabel: formattedDates[dateIndex],
              shiftLabel: isDay ? 'Day' : 'Night',
              retestRate: i < rr.length ? rr[i] : null,
              input: i < input.length ? input[i] : null,
              firstFail: i < firstFail.length ? firstFail[i] : null,
              retestFail: i < retestFail.length ? retestFail[i] : null,
              pass: i < pass.length ? pass[i] : null,
            );
          },
        );

        final cells = <DataCell>[
          DataCell(_ValueLabel(firstGroup ? '$index' : '')),
          DataCell(_ValueLabel(firstGroup ? row.modelName : '')),
          DataCell(
            _GroupCell(
              label: group,
              onTap: onGroupTap == null
                  ? null
                  : () {
                      onGroupTap!.call(
                        TERetestGroupDetail(
                          modelName: row.modelName,
                          groupName: group,
                          cells: List.unmodifiable(groupDetails),
                        ),
                      );
                    },
            ),
          ),
          ...groupDetails.map(
            (detailItem) => DataCell(
              _RetestValueCell(
                detail: detailItem,
                onTap: onCellTap,
              ),
            ),
          ),
        ];

        rows.add(
          DataRow(
            cells: cells,
            color: MaterialStateProperty.all(_rowColor),
          ),
        );
        firstGroup = false;
      }
      index++;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF07192F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33040E1C),
            blurRadius: 22,
            offset: Offset(0, 14),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(_headerColor),
            columnSpacing: 16,
            horizontalMargin: 16,
            dataRowHeight: 62,
            headingRowHeight: 64,
            dividerThickness: 0.6,
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _DateHeaderLabel extends StatelessWidget {
  const _DateHeaderLabel({required this.date, required this.shift});

  final String date;
  final String shift;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          date,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          shift,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ValueLabel extends StatelessWidget {
  const _ValueLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _GroupCell extends StatelessWidget {
  const _GroupCell({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 6),
          const Icon(Icons.area_chart, size: 16, color: Colors.white54),
        ],
      ],
    );
    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: content,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
          child: content,
        ),
      ),
    );
  }
}

class _RetestValueCell extends StatelessWidget {
  const _RetestValueCell({required this.detail, this.onTap});

  final TERetestCellDetail detail;
  final ValueChanged<TERetestCellDetail>? onTap;

  static const _dangerColor = Color(0xFFFF6B6B);
  static const _warningColor = Color(0xFFFFC56F);
  static const _normalColor = Color(0xFF38D893);

  @override
  Widget build(BuildContext context) {
    final value = detail.retestRate;
    final Color background;
    final Color textColor;
    if (value == null) {
      background = Colors.transparent;
      textColor = Colors.white60;
    } else if (value >= 5) {
      background = _dangerColor.withOpacity(0.16);
      textColor = _dangerColor;
    } else if (value >= 3) {
      background = _warningColor.withOpacity(0.18);
      textColor = _warningColor;
    } else {
      background = _normalColor.withOpacity(0.18);
      textColor = _normalColor;
    }

    final tooltip = _buildTooltip(detail);

    Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: background == Colors.transparent ? Colors.white12 : background.withOpacity(0.7)),
      ),
      child: Text(
        value == null ? 'N/A' : '${value.toStringAsFixed(2)}%',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );

    child = Tooltip(
      message: tooltip,
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: child,
    );

    if (onTap != null) {
      child = GestureDetector(onTap: () => onTap!(detail), child: child);
    }

    return Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: child);
  }

  String _buildTooltip(TERetestCellDetail detail) {
    final buffer = StringBuffer()
      ..writeln('${detail.dateLabel} (${detail.shiftLabel})')
      ..writeln('Retest Rate: ${detail.retestRate == null ? 'N/A' : '${detail.retestRate!.toStringAsFixed(2)}%'}')
      ..writeln('WIP Qty: ${detail.input ?? 0}')
      ..writeln('First Fail: ${detail.firstFail ?? 0}')
      ..writeln('Retest Fail: ${detail.retestFail ?? 0}')
      ..writeln('Pass Qty: ${detail.pass ?? 0}');
    return buffer.toString();
  }
}

class TERetestCellDetail {
  const TERetestCellDetail({
    required this.modelName,
    required this.groupName,
    required this.dateLabel,
    required this.shiftLabel,
    required this.retestRate,
    required this.input,
    required this.firstFail,
    required this.retestFail,
    required this.pass,
  });

  final String modelName;
  final String groupName;
  final String dateLabel;
  final String shiftLabel;
  final double? retestRate;
  final int? input;
  final int? firstFail;
  final int? retestFail;
  final int? pass;
}

class TERetestGroupDetail {
  const TERetestGroupDetail({
    required this.modelName,
    required this.groupName,
    required this.cells,
  });

  final String modelName;
  final String groupName;
  final List<TERetestCellDetail> cells;
}
