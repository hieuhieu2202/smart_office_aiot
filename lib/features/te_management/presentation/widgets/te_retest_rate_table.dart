import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/te_retest_rate.dart';

const double _kIndexWidth = 64;
const double _kModelWidth = 220;
const double _kGroupWidth = 200;
const double _kCellWidth = 120;
const double _kHeaderTopHeight = 44;
const double _kHeaderBottomHeight = 36;
const double _kRowHeight = 60;

const Color _kHeaderColor = Color(0xFF112F55);
const Color _kHeaderAccent = Color(0xFF173C6B);
const Color _kTableBackground = Color(0xFF06152A);
const Color _kRowEvenColor = Color(0x33163D63);
const Color _kRowOddColor = Color(0x22163D63);
const Color _kSpanBackground = Color(0xFF0D2647);
const Color _kBorderColor = Color(0x3342B8FF);
const BorderSide _kGridBorder = BorderSide(color: _kBorderColor, width: 1);

class TERetestRateTable extends StatefulWidget {
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

  @override
  State<TERetestRateTable> createState() => _TERetestRateTableState();
}

class _TERetestRateTableState extends State<TERetestRateTable> {
  late final ScrollController _horizontalController;
  late final ScrollController _verticalController;

  int get _totalColumns => widget.formattedDates.length * 2;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
    _verticalController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.detail.hasData || widget.formattedDates.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final totalWidth =
        _kIndexWidth + _kModelWidth + _kGroupWidth + (_totalColumns * _kCellWidth);

    return LayoutBuilder(
      builder: (context, constraints) {
        final headerHeight = _kHeaderTopHeight + _kHeaderBottomHeight;
        final minimumHeight = headerHeight + _kRowHeight;
        final totalGroupRows = widget.detail.rows.fold<int>(
          0,
          (sum, row) => sum + math.max(row.groupNames.length, 1),
        );
        final naturalHeight =
            headerHeight + (totalGroupRows * _kRowHeight.toDouble());

        final hasFiniteHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        final resolvedHeight = hasFiniteHeight
            ? math.max(constraints.maxHeight, minimumHeight)
            : math.max(naturalHeight, minimumHeight);

        final hasFiniteWidth =
            constraints.hasBoundedWidth && constraints.maxWidth.isFinite;
        final resolvedWidth = hasFiniteWidth
            ? math.max(constraints.maxWidth, _kIndexWidth + _kModelWidth)
            : math.max(totalWidth, constraints.minWidth);

        final tableWidth = math.max(totalWidth, resolvedWidth);
        final bodyHeight = math.max(
          resolvedHeight - headerHeight,
          _kRowHeight.toDouble(),
        );

        Widget surface = SizedBox(
          width: resolvedWidth,
          height: resolvedHeight,
          child: DecoratedBox(
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
                controller: _horizontalController,
                thumbVisibility: true,
                trackVisibility: false,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    height: resolvedHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeaderRow(
                          formattedDates: widget.formattedDates,
                        ),
                        SizedBox(
                          height: bodyHeight,
                          child: Scrollbar(
                            controller: _verticalController,
                            thumbVisibility: true,
                            trackVisibility: false,
                            child: ListView.builder(
                              controller: _verticalController,
                              padding: EdgeInsets.zero,
                              itemCount: widget.detail.rows.length,
                              itemBuilder: (context, index) {
                                final row = widget.detail.rows[index];
                                final isFirst = index == 0;
                                return _ModelBlock(
                                  index: index + 1,
                                  row: row,
                                  formattedDates: widget.formattedDates,
                                  totalColumns: _totalColumns,
                                  isFirstBlock: isFirst,
                                  onCellTap: widget.onCellTap,
                                  onGroupTap: widget.onGroupTap,
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
          ),
        );

        if (hasFiniteWidth && hasFiniteHeight) {
          surface = SizedBox.expand(child: surface);
        }

        return surface;
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.formattedDates,
  });

  final List<String> formattedDates;

  double get _fullHeight => _kHeaderTopHeight + _kHeaderBottomHeight;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kHeaderColor, _kHeaderAccent],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderBlock(
            width: _kIndexWidth,
            child: const _HeaderLabel('#'),
          ),
          _HeaderBlock(
            width: _kModelWidth,
            child: const _HeaderLabel(
              'MODEL NAME',
              alignment: Alignment.centerLeft,
            ),
          ),
          _HeaderBlock(
            width: _kGroupWidth,
            child: const _HeaderLabel(
              'GROUP NAME',
              alignment: Alignment.centerLeft,
            ),
          ),
          for (final date in formattedDates)
            SizedBox(
              width: _kCellWidth * 2,
              height: _fullHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: _kHeaderTopHeight,
                    decoration: const BoxDecoration(
                      border: Border(
                        right: _kGridBorder,
                        bottom: _kGridBorder,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: _kHeaderBottomHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        _HeaderShiftCell(label: 'Day'),
                        _HeaderShiftCell(label: 'Night'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock({
    required this.width,
    required this.child,
  });

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _kHeaderTopHeight + _kHeaderBottomHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            right: _kGridBorder,
            bottom: _kGridBorder,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(
    this.text, {
    this.alignment = Alignment.center,
  });

  final String text;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: alignment == Alignment.center ? 8 : 16,
      ),
      child: Align(
        alignment: alignment,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _HeaderShiftCell extends StatelessWidget {
  const _HeaderShiftCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            right: _kGridBorder,
            bottom: _kGridBorder,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
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
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF14355E),
              _kSpanBackground,
            ],
          ),
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

    final startColor = Color.alphaBlend(const Color(0x33264986), background);
    final endColor = Color.alphaBlend(const Color(0x11264986), background);

    final decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [startColor, endColor],
      ),
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
    Color fillColor = Color.alphaBlend(const Color(0x1A1F3147), background);
    Color textColor = Colors.white60;
    Color outlineColor = Colors.white12;
    if (value != null) {
      if (value >= 5) {
        fillColor = const Color(0x29FF6B6B);
        textColor = _dangerColor;
        outlineColor = _dangerColor.withOpacity(0.35);
      } else if (value >= 3) {
        fillColor = const Color(0x26FFC56F);
        textColor = _warningColor;
        outlineColor = _warningColor.withOpacity(0.35);
      } else {
        fillColor = const Color(0x2538D893);
        textColor = _normalColor;
        outlineColor = _normalColor.withOpacity(0.35);
      }
    } else {
      textColor = Colors.white54;
    }

    final tooltip = _buildTooltip(detail);

    Widget cell = Container(
      height: _kRowHeight,
      decoration: BoxDecoration(
        color: fillColor,
        border: Border(
          right: showRightBorder ? _kGridBorder : BorderSide.none,
          top: isFirstRow ? _kGridBorder : BorderSide.none,
          bottom: _kGridBorder,
        ),
        boxShadow: value == null
            ? const []
            : [
                BoxShadow(
                  color: outlineColor,
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: outlineColor, width: 1),
          borderRadius: BorderRadius.circular(10),
          color: value == null ? Colors.transparent : fillColor.withOpacity(0.65),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
