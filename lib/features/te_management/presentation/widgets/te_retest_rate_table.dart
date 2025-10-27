import 'package:flutter/material.dart';

import '../../domain/entities/te_retest_rate.dart';

const double _kIndexWidth = 64;
const double _kModelWidth = 220;
const double _kGroupWidth = 200;
const double _kCellWidth = 120;
const double _kHeaderTopHeight = 44;
const double _kHeaderBottomHeight = 36;
const double _kRowHeight = 60;

const Color _kHeaderColor = Color(0xFF0F2748);
const Color _kTableBackground = Color(0xFF07192F);
const Color _kRowEvenColor = Color(0x120E3A67);
const Color _kRowOddColor = Color(0x080E3A67);
const Color _kSpanBackground = Color(0xFF0B2343);
const Color _kBorderColor = Color(0x332BD4F5);
const BorderSide _kGridBorder = BorderSide(color: _kBorderColor, width: 1);

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

    final totalWidth =
        _kIndexWidth + _kModelWidth + _kGroupWidth + (_totalColumns * _kCellWidth);

    final horizontalController = ScrollController();
    final verticalController = ScrollController();

    return LayoutBuilder(
      builder: (context, constraints) {
        final headerHeight = _kHeaderTopHeight + _kHeaderBottomHeight;
        final availableHeight = constraints.hasBoundedHeight
            ? (constraints.maxHeight - headerHeight - 1)
            : null;
        final bodyHeight = availableHeight != null && availableHeight > 0
            ? availableHeight
            : detail.rows.length * _kRowHeight.toDouble();

        return DecoratedBox(
          decoration: BoxDecoration(
            color: _kTableBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kBorderColor),
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
            child: Scrollbar(
              controller: horizontalController,
              thumbVisibility: true,
              trackVisibility: false,
              child: SingleChildScrollView(
                controller: horizontalController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: totalWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderRow(formattedDates: formattedDates, totalColumns: _totalColumns),
                      const Divider(height: 1, thickness: 1, color: _kBorderColor),
                      SizedBox(
                        height: bodyHeight,
                        child: Scrollbar(
                          controller: verticalController,
                          thumbVisibility: true,
                          trackVisibility: false,
                          child: ListView.builder(
                            controller: verticalController,
                            padding: EdgeInsets.zero,
                            itemCount: detail.rows.length,
                            itemBuilder: (context, index) {
                              final row = detail.rows[index];
                              final isFirst = index == 0;
                              return _ModelBlock(
                                index: index + 1,
                                row: row,
                                formattedDates: formattedDates,
                                totalColumns: _totalColumns,
                                isFirstBlock: isFirst,
                                onCellTap: onCellTap,
                                onGroupTap: onGroupTap,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.formattedDates,
    required this.totalColumns,
  });

  final List<String> formattedDates;
  final int totalColumns;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kHeaderColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _HeaderCell(
                width: _kIndexWidth,
                height: _kHeaderTopHeight + _kHeaderBottomHeight,
                label: '#',
              ),
              _HeaderCell(
                width: _kModelWidth,
                height: _kHeaderTopHeight + _kHeaderBottomHeight,
                label: 'MODEL NAME',
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _HeaderCell(
                width: _kGroupWidth,
                height: _kHeaderTopHeight + _kHeaderBottomHeight,
                label: 'GROUP NAME',
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              for (final date in formattedDates)
                _HeaderCell(
                  width: _kCellWidth * 2,
                  height: _kHeaderTopHeight,
                  label: date,
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
            ],
          ),
          Row(
            children: [
              const _HeaderSpacer(width: _kIndexWidth),
              const _HeaderSpacer(width: _kModelWidth),
              const _HeaderSpacer(width: _kGroupWidth),
              for (var i = 0; i < totalColumns; i++)
                _HeaderCell(
                  width: _kCellWidth,
                  height: _kHeaderBottomHeight,
                  label: i.isEven ? 'Day' : 'Night',
                  textStyle: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  border: const Border(
                    right: _kGridBorder,
                    top: _kGridBorder,
                    bottom: _kGridBorder,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.width,
    required this.height,
    required this.label,
    this.alignment = Alignment.center,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.textStyle,
    this.border,
  });

  final double width;
  final double height;
  final String label;
  final Alignment alignment;
  final EdgeInsets padding;
  final TextStyle? textStyle;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: border ?? const Border(right: _kGridBorder, bottom: _kGridBorder),
        ),
        child: Padding(
          padding: padding,
          child: Align(
            alignment: alignment,
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: textStyle ??
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderSpacer extends StatelessWidget {
  const _HeaderSpacer({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _kHeaderBottomHeight,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            right: _kGridBorder,
            top: _kGridBorder,
            bottom: _kGridBorder,
          ),
        ),
      ),
    );
  }
}

class _ModelBlock extends StatelessWidget {
  const _ModelBlock({
    required this.index,
    required this.row,
    required this.formattedDates,
    required this.totalColumns,
    required this.isFirstBlock,
    required this.onCellTap,
    required this.onGroupTap,
  });

  final int index;
  final TERetestDetailRowEntity row;
  final List<String> formattedDates;
  final int totalColumns;
  final bool isFirstBlock;
  final ValueChanged<TERetestCellDetail>? onCellTap;
  final ValueChanged<TERetestGroupDetail>? onGroupTap;

  @override
  Widget build(BuildContext context) {
    final groupCount = row.groupNames.length;
    final blockHeight = (groupCount == 0 ? 1 : groupCount) * _kRowHeight;
    final dataWidth = _kGroupWidth + (totalColumns * _kCellWidth);

    final groupRows = <Widget>[];

    for (var g = 0; g < groupCount; g++) {
      final groupName = row.groupNames[g];
      final rr = row.retestRate[groupName] ?? const <double?>[];
      final input = row.input[groupName] ?? const <int?>[];
      final firstFail = row.firstFail[groupName] ?? const <int?>[];
      final retestFail = row.retestFail[groupName] ?? const <int?>[];
      final pass = row.pass[groupName] ?? const <int?>[];

      final cells = List<TERetestCellDetail>.generate(
        totalColumns,
        (i) {
          final dateIndex = i ~/ 2;
          final isDay = i.isEven;
          return TERetestCellDetail(
            modelName: row.modelName,
            groupName: groupName,
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

      final background = g.isEven ? _kRowEvenColor : _kRowOddColor;
      final isRowFirst = isFirstBlock && g == 0;

      groupRows.add(
        SizedBox(
          height: _kRowHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _kGroupWidth,
                child: _GroupCell(
                  label: groupName,
                  background: background,
                  onTap: onGroupTap == null
                      ? null
                      : () => onGroupTap!(
                            TERetestGroupDetail(
                              modelName: row.modelName,
                              groupName: groupName,
                              cells: List.unmodifiable(cells),
                            ),
                          ),
                  isFirstRow: isRowFirst,
                ),
              ),
              for (var i = 0; i < cells.length; i++)
                SizedBox(
                  width: _kCellWidth,
                  child: _RetestValueCell(
                    detail: cells[i],
                    background: background,
                    onTap: onCellTap,
                    isFirstRow: isRowFirst,
                    showRightBorder: true,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (groupRows.isEmpty) {
      final placeholderCells = List<TERetestCellDetail>.generate(
        totalColumns,
        (i) {
          final dateIndex = i ~/ 2;
          final isDay = i.isEven;
          final hasDates = formattedDates.isNotEmpty;
          final safeIndex = hasDates
              ? (dateIndex < formattedDates.length
                  ? dateIndex
                  : formattedDates.length - 1)
              : 0;
          final dateLabel = hasDates ? formattedDates[safeIndex] : '-';
          return TERetestCellDetail(
            modelName: row.modelName,
            groupName: '-',
            dateLabel: dateLabel,
            shiftLabel: isDay ? 'Day' : 'Night',
            retestRate: null,
            input: null,
            firstFail: null,
            retestFail: null,
            pass: null,
          );
        },
      );

      final background = _kRowEvenColor;
      groupRows.add(
        SizedBox(
          height: _kRowHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _kGroupWidth,
                child: _GroupCell(
                  label: '-',
                  background: background,
                  isFirstRow: isFirstBlock,
                ),
              ),
              for (final cellDetail in placeholderCells)
                SizedBox(
                  width: _kCellWidth,
                  child: _RetestValueCell(
                    detail: cellDetail,
                    background: background,
                    onTap: onCellTap,
                    isFirstRow: isFirstBlock,
                    showRightBorder: true,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: _kIndexWidth + _kModelWidth + dataWidth,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SpanCell(
            width: _kIndexWidth,
            height: blockHeight,
            label: index.toString(),
            alignment: Alignment.center,
            isFirst: isFirstBlock,
          ),
          _SpanCell(
            width: _kModelWidth,
            height: blockHeight,
            label: row.modelName,
            alignment: Alignment.centerLeft,
            isFirst: isFirstBlock,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(
            width: dataWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: groupRows,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpanCell extends StatelessWidget {
  const _SpanCell({
    required this.width,
    required this.height,
    required this.label,
    required this.alignment,
    required this.isFirst,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.textStyle,
  });

  final double width;
  final double height;
  final String label;
  final Alignment alignment;
  final bool isFirst;
  final EdgeInsets padding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final style = textStyle ??
        const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        );

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _kSpanBackground,
          border: Border(
            top: isFirst ? _kGridBorder : BorderSide.none,
            right: _kGridBorder,
            bottom: _kGridBorder,
          ),
        ),
        child: Padding(
          padding: padding,
          child: Align(
            alignment: alignment,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupCell extends StatelessWidget {
  const _GroupCell({
    required this.label,
    required this.background,
    this.onTap,
    required this.isFirstRow,
  });

  final String label;
  final Color background;
  final VoidCallback? onTap;
  final bool isFirstRow;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

    final decoration = BoxDecoration(
      color: background,
      border: Border(
        left: _kGridBorder,
        right: _kGridBorder,
        top: isFirstRow ? _kGridBorder : BorderSide.none,
        bottom: _kGridBorder,
      ),
    );

    final child = Container(
      height: _kRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: decoration,
      alignment: Alignment.centerLeft,
      child: content,
    );

    if (onTap == null) {
      return child;
    }

    return InkWell(
      onTap: onTap,
      splashColor: Colors.white10,
      borderRadius: BorderRadius.zero,
      child: child,
    );
  }
}

class _RetestValueCell extends StatelessWidget {
  const _RetestValueCell({
    required this.detail,
    required this.background,
    this.onTap,
    required this.isFirstRow,
    required this.showRightBorder,
  });

  final TERetestCellDetail detail;
  final Color background;
  final ValueChanged<TERetestCellDetail>? onTap;
  final bool isFirstRow;
  final bool showRightBorder;

  static const Color _dangerColor = Color(0xFFFF6B6B);
  static const Color _warningColor = Color(0xFFFFC56F);
  static const Color _normalColor = Color(0xFF38D893);

  @override
  Widget build(BuildContext context) {
    final value = detail.retestRate;
    final Color chipColor;
    final Color textColor;
    if (value == null) {
      chipColor = Colors.transparent;
      textColor = Colors.white60;
    } else if (value >= 5) {
      chipColor = _dangerColor.withOpacity(0.16);
      textColor = _dangerColor;
    } else if (value >= 3) {
      chipColor = _warningColor.withOpacity(0.18);
      textColor = _warningColor;
    } else {
      chipColor = _normalColor.withOpacity(0.18);
      textColor = _normalColor;
    }

    final tooltip = _buildTooltip(detail);

    Widget cell = Container(
      height: _kRowHeight,
      decoration: BoxDecoration(
        color: background,
        border: Border(
          right: showRightBorder ? _kGridBorder : BorderSide.none,
          top: isFirstRow ? _kGridBorder : BorderSide.none,
          bottom: _kGridBorder,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: chipColor == Colors.transparent
                ? Colors.white12
                : chipColor.withOpacity(0.7),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          value == null ? 'N/A' : '${value.toStringAsFixed(2)}%',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );

    cell = Tooltip(
      message: tooltip,
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: cell,
    );

    if (onTap != null) {
      cell = GestureDetector(onTap: () => onTap!(detail), child: cell);
    }

    return cell;
  }

  String _buildTooltip(TERetestCellDetail detail) {
    final buffer = StringBuffer()
      ..writeln('${detail.dateLabel} (${detail.shiftLabel})')
      ..writeln(
          'Retest Rate: ${detail.retestRate == null ? 'N/A' : '${detail.retestRate!.toStringAsFixed(2)}%'}')
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
