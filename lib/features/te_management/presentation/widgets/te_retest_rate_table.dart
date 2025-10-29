import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/te_retest_rate.dart';

const double _kIndexBaseWidth = 58;
const double _kIndexMinWidth = 46;
const double _kModelBaseWidth = 220;
const double _kModelMinWidth = 160;
const double _kGroupBaseWidth = 360;
const double _kGroupMinWidth = 240;
const double _kCellBaseWidth = 108;
const double _kCellMinWidth = 72;
const double _kHeaderTopHeight = 40;
const double _kHeaderBottomHeight = 32;
const double _kRowHeight = 54;

const Color _kHeaderColor = Color(0xFF0A2342);
const Color _kHeaderAccent = Color(0xFF112F54);
const Color _kTableBackground = Color(0xFF010A18);
const Color _kRowEvenColor = Color(0xFF0B1E36);
const Color _kRowOddColor = Color(0xFF08162B);
const Color _kSpanBackground = Color(0xFF103055);
const Color _kBorderColor = Color(0x7737B8FF);
const BorderSide _kGridBorder = BorderSide(color: _kBorderColor, width: 1.0);

class TERetestRateTable extends StatefulWidget {
  const TERetestRateTable({
    super.key,
    required this.detail,
    required this.formattedDates,
    this.onCellTap,
    this.onGroupTap,
    required this.highlightCells,
  });

  final TERetestDetailEntity detail;
  final List<String> formattedDates;
  final ValueChanged<TERetestCellDetail>? onCellTap;
  final ValueChanged<TERetestGroupDetail>? onGroupTap;
  final Set<String> highlightCells;

  @override
  State<TERetestRateTable> createState() => _TERetestRateTableState();
}

class _TERetestRateTableState extends State<TERetestRateTable> {
  late final ScrollController _horizontalHeaderController;
  late final ScrollController _horizontalBodyController;
  late final ScrollController _verticalBodyController;
  late final VoidCallback _headerScrollListener;
  late final VoidCallback _bodyScrollListener;
  bool _isSyncingHorizontal = false;

  int get _totalColumns => widget.formattedDates.length * 2;

  _TableMetrics _resolveMetrics(double availableWidth) {
    final columns = math.max(_totalColumns, 1);
    final width = availableWidth > 0 ? availableWidth : 1.0;

    final double effectiveMinTotal =
        _kIndexMinWidth + _kModelMinWidth + _kGroupMinWidth + (columns * _kCellMinWidth);

    final double baseTotal =
        _kIndexBaseWidth + _kModelBaseWidth + _kGroupBaseWidth + (columns * _kCellBaseWidth);

    double indexWidth;
    double modelWidth;
    double groupWidth;
    double cellWidth;

    if (width <= effectiveMinTotal) {
      final scale = width / effectiveMinTotal;
      indexWidth = _kIndexMinWidth * scale;
      modelWidth = _kModelMinWidth * scale;
      groupWidth = _kGroupMinWidth * scale;
      cellWidth = _kCellMinWidth * scale;
    } else if (width >= baseTotal) {
      indexWidth = _kIndexBaseWidth;
      modelWidth = _kModelBaseWidth;
      groupWidth = _kGroupBaseWidth;
      final remaining = width - (_kIndexBaseWidth + _kModelBaseWidth + _kGroupBaseWidth);
      cellWidth = remaining / columns;
    } else {
      final ratio = (width - effectiveMinTotal) / (baseTotal - effectiveMinTotal);
      indexWidth =
          _kIndexMinWidth + (_kIndexBaseWidth - _kIndexMinWidth) * ratio;
      modelWidth =
          _kModelMinWidth + (_kModelBaseWidth - _kModelMinWidth) * ratio;
      groupWidth =
          _kGroupMinWidth + (_kGroupBaseWidth - _kGroupMinWidth) * ratio;
      cellWidth =
          _kCellMinWidth + (_kCellBaseWidth - _kCellMinWidth) * ratio;
    }

    final fixedWidth = indexWidth + modelWidth + groupWidth;
    final remainingWidth = (width - fixedWidth).clamp(0.0, double.infinity);
    cellWidth = columns > 0 ? remainingWidth / columns : 0;

    final totalWidth = width;

    return _TableMetrics(
      indexWidth: indexWidth,
      modelWidth: modelWidth,
      groupWidth: groupWidth,
      cellWidth: cellWidth,
      totalWidth: totalWidth,
    );
  }

  @override
  void initState() {
    super.initState();
    _horizontalHeaderController = ScrollController();
    _horizontalBodyController = ScrollController();
    _verticalBodyController = ScrollController();

    _headerScrollListener = () => _syncHorizontal(fromHeader: true);
    _bodyScrollListener = () => _syncHorizontal(fromHeader: false);

    _horizontalHeaderController.addListener(_headerScrollListener);
    _horizontalBodyController.addListener(_bodyScrollListener);
  }

  @override
  void dispose() {
    _horizontalHeaderController.removeListener(_headerScrollListener);
    _horizontalBodyController.removeListener(_bodyScrollListener);
    _horizontalHeaderController.dispose();
    _horizontalBodyController.dispose();
    _verticalBodyController.dispose();
    super.dispose();
  }

  void _syncHorizontal({required bool fromHeader}) {
    if (_isSyncingHorizontal) return;
    if (!_horizontalHeaderController.hasClients ||
        !_horizontalBodyController.hasClients) {
      return;
    }

    final source = fromHeader
        ? _horizontalHeaderController
        : _horizontalBodyController;
    final target = fromHeader
        ? _horizontalBodyController
        : _horizontalHeaderController;

    final offset = source.offset;
    final minExtent = target.position.minScrollExtent;
    final maxExtent = target.position.maxScrollExtent;
    final clampedOffset = offset.clamp(minExtent, maxExtent).toDouble();

    if ((target.offset - clampedOffset).abs() < 0.5) {
      return;
    }

    _isSyncingHorizontal = true;
    target.jumpTo(clampedOffset);
    _isSyncingHorizontal = false;
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

    const headerHeight = _kHeaderTopHeight + _kHeaderBottomHeight;
    final totalGroupRows = widget.detail.rows.fold<int>(
      0,
      (sum, row) => sum + math.max(row.groupNames.length, 1),
    );
    final naturalHeight =
        headerHeight + (totalGroupRows * _kRowHeight.toDouble());
    final fallbackTotalWidth = _kIndexBaseWidth +
        _kModelBaseWidth +
        _kGroupBaseWidth +
        (_totalColumns * _kCellBaseWidth);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedWidth =
            constraints.hasBoundedWidth && constraints.maxWidth.isFinite;
        final hasBoundedHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

        final width = hasBoundedWidth
            ? constraints.maxWidth
            : math.max(fallbackTotalWidth.toDouble(), constraints.minWidth);
        final height = hasBoundedHeight
            ? constraints.maxHeight
            : math.max(naturalHeight, constraints.minHeight.toDouble());
        final metrics = _resolveMetrics(width);
        final tableWidth = metrics.totalWidth > 0 ? metrics.totalWidth : width;

        return SizedBox(
          width: width,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _kTableBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kBorderColor),
              boxShadow: const [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: headerHeight,
                    child: Scrollbar(
                      controller: _horizontalHeaderController,
                      thumbVisibility: false,
                      child: SingleChildScrollView(
                        controller: _horizontalHeaderController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: tableWidth,
                          height: headerHeight,
                          child: _HeaderRow(
                            formattedDates: widget.formattedDates,
                            metrics: metrics,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.transparent),
                  Expanded(
                    child: Scrollbar(
                      controller: _horizontalBodyController,
                      thumbVisibility: false,
                      child: SingleChildScrollView(
                        controller: _horizontalBodyController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: tableWidth,
                          child: Scrollbar(
                            controller: _verticalBodyController,
                            thumbVisibility: true,
                            child: ListView.builder(
                              controller: _verticalBodyController,
                              padding: EdgeInsets.zero,
                              physics: const ClampingScrollPhysics(),
                              itemCount: widget.detail.rows.length,
                              itemBuilder: (context, index) {
                                final row = widget.detail.rows[index];
                                return _ModelBlock(
                                  index: index + 1,
                                  row: row,
                                  formattedDates: widget.formattedDates,
                                  rawDates: widget.detail.dates,
                                  totalColumns: _totalColumns,
                                  isFirstBlock: index == 0,
                                  onCellTap: widget.onCellTap,
                                  onGroupTap: widget.onGroupTap,
                                  metrics: metrics,
                                  highlightCells: widget.highlightCells,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TableMetrics {
  const _TableMetrics({
    required this.indexWidth,
    required this.modelWidth,
    required this.groupWidth,
    required this.cellWidth,
    required this.totalWidth,
  });

  final double indexWidth;
  final double modelWidth;
  final double groupWidth;
  final double cellWidth;
  final double totalWidth;
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.formattedDates,
    required this.metrics,
  });

  final List<String> formattedDates;
  final _TableMetrics metrics;

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
            width: metrics.indexWidth,
            showLeftBorder: true,
            child: const _HeaderLabel('#'),
          ),
          _HeaderBlock(
            width: metrics.modelWidth,
            child: const _HeaderLabel(
              'MODEL NAME',
              alignment: Alignment.centerLeft,
            ),
          ),
          _HeaderBlock(
            width: metrics.groupWidth,
            child: const _HeaderLabel(
              'GROUP NAME',
              alignment: Alignment.centerLeft,
            ),
          ),
          for (var dateIndex = 0; dateIndex < formattedDates.length; dateIndex++)
            SizedBox(
              width: metrics.cellWidth * 2,
              height: _fullHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: _kHeaderTopHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        left: dateIndex == 0 ? _kGridBorder : BorderSide.none,
                        right: _kGridBorder,
                        top: _kGridBorder,
                        bottom: _kGridBorder,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      formattedDates[dateIndex],
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
                      children: [
                        _HeaderShiftCell(
                          label: 'Day',
                          showLeftBorder: dateIndex == 0,
                          showTopBorder: true,
                        ),
                        const _HeaderShiftCell(
                          label: 'Night',
                          showLeftBorder: true,
                          showTopBorder: true,
                        ),
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
    this.showLeftBorder = false,
  });

  final double width;
  final Widget child;
  final bool showLeftBorder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _kHeaderTopHeight + _kHeaderBottomHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: showLeftBorder ? _kGridBorder : BorderSide.none,
            right: _kGridBorder,
            top: _kGridBorder,
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
  const _HeaderShiftCell({
    required this.label,
    this.showLeftBorder = false,
    this.showRightBorder = true,
    this.showTopBorder = false,
  });

  final String label;
  final bool showLeftBorder;
  final bool showRightBorder;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: showLeftBorder ? _kGridBorder : BorderSide.none,
            right: showRightBorder ? _kGridBorder : BorderSide.none,
            top: showTopBorder ? _kGridBorder : BorderSide.none,
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
    required this.rawDates,
    required this.totalColumns,
    required this.isFirstBlock,
    required this.onCellTap,
    required this.onGroupTap,
    required this.metrics,
    required this.highlightCells,
  });

  final int index;
  final TERetestDetailRowEntity row;
  final List<String> formattedDates;
  final List<String> rawDates;
  final int totalColumns;
  final bool isFirstBlock;
  final ValueChanged<TERetestCellDetail>? onCellTap;
  final ValueChanged<TERetestGroupDetail>? onGroupTap;
  final _TableMetrics metrics;
  final Set<String> highlightCells;

  @override
  Widget build(BuildContext context) {
    final groupCount = row.groupNames.length;
    final blockHeight = (groupCount == 0 ? 1 : groupCount) * _kRowHeight;
    final dataWidth = metrics.groupWidth + (totalColumns * metrics.cellWidth);

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
          final rawDate =
              dateIndex < rawDates.length ? rawDates[dateIndex] : '';
          return TERetestCellDetail(
            modelName: row.modelName,
            groupName: groupName,
            dateLabel: formattedDates[dateIndex],
            dateKey: rawDate,
            shiftLabel: isDay ? 'Day' : 'Night',
            isDayShift: isDay,
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
              _GroupCell(
                width: metrics.groupWidth,
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
              for (var i = 0; i < cells.length; i++)
                SizedBox(
                  width: metrics.cellWidth,
                  child: _RetestValueCell(
                    detail: cells[i],
                    background: background,
                    onTap: onCellTap,
                    isFirstRow: isRowFirst,
                    showRightBorder: i < cells.length - 1,
                    highlighted: highlightCells.contains(
                      buildRetestCellKey(row.modelName, groupName, i),
                    ),
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
          final rawDate =
              safeIndex < rawDates.length ? rawDates[safeIndex] : '';
          final dateLabel = hasDates ? formattedDates[safeIndex] : '-';
          return TERetestCellDetail(
            modelName: row.modelName,
            groupName: '-',
            dateLabel: dateLabel,
            dateKey: rawDate,
            shiftLabel: isDay ? 'Day' : 'Night',
            isDayShift: isDay,
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
              _GroupCell(
                width: metrics.groupWidth,
                label: '-',
                background: background,
                isFirstRow: isFirstBlock,
              ),
              for (var i = 0; i < placeholderCells.length; i++)
                SizedBox(
                  width: metrics.cellWidth,
                  child: _RetestValueCell(
                    detail: placeholderCells[i],
                    background: background,
                    onTap: onCellTap,
                    isFirstRow: isFirstBlock,
                    showRightBorder: i < placeholderCells.length - 1,
                    highlighted: false,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: metrics.totalWidth,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SpanCell(
            width: metrics.indexWidth,
            height: blockHeight,
            label: index.toString(),
            alignment: Alignment.center,
            isFirst: isFirstBlock,
          ),
          _SpanCell(
            width: metrics.modelWidth,
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
    required this.width,
    required this.label,
    required this.background,
    this.onTap,
    required this.isFirstRow,
  });

  final double width;
  final String label;
  final Color background;
  final VoidCallback? onTap;
  final bool isFirstRow;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 6),
          const Icon(Icons.area_chart, size: 16, color: Colors.white70),
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

    final child = SizedBox(
      width: width,
      child: Container(
        height: _kRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: decoration,
        alignment: Alignment.center,
        child: content,
      ),
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
    required this.highlighted,
  });

  final TERetestCellDetail detail;
  final Color background;
  final ValueChanged<TERetestCellDetail>? onTap;
  final bool isFirstRow;
  final bool showRightBorder;
  final bool highlighted;

  static const Color _dangerColor = Color(0xFFE11D48);
  static const Color _warningColor = Color(0xFFF59E0B);
  static const Color _normalColor = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    final value = detail.retestRate;
    Color fillColor = Color.alphaBlend(const Color(0x14000000), background);
    Color textColor = Colors.white70;
    if (value != null) {
      if (value >= 5) {
        fillColor = const Color(0x33F87171);
        textColor = _dangerColor;
      } else if (value >= 3) {
        fillColor = const Color(0x33FACC15);
        textColor = _warningColor;
      } else {
        fillColor = const Color(0x3322C55E);
        textColor = _normalColor;
      }
    } else {
      textColor = Colors.white54;
    }

    final tooltip = _buildTooltip(detail);

    final animatedColor = highlighted
        ? Color.lerp(fillColor, const Color(0xFF38BDF8), 0.4) ?? fillColor
        : fillColor;
    final effectiveTextColor = highlighted
        ? Color.lerp(textColor, Colors.white, 0.35) ?? textColor
        : textColor;

    Widget cell = AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      height: _kRowHeight,
      decoration: BoxDecoration(
        color: animatedColor,
        border: Border(
          right: showRightBorder ? _kGridBorder : BorderSide.none,
          top: isFirstRow ? _kGridBorder : BorderSide.none,
          bottom: _kGridBorder,
        ),
        boxShadow: highlighted
            ? const [
                BoxShadow(
                  color: Color(0x5528D8FF),
                  blurRadius: 18,
                  spreadRadius: 1.2,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      child: Text(
        value == null ? 'N/A' : '${value.toStringAsFixed(2)}%',
        style: TextStyle(
          color: effectiveTextColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );

    cell = Tooltip(
      message: tooltip,
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: BoxDecoration(
        color: _kSpanBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
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
    required this.dateKey,
    required this.shiftLabel,
    required this.isDayShift,
    required this.retestRate,
    required this.input,
    required this.firstFail,
    required this.retestFail,
    required this.pass,
  });

  final String modelName;
  final String groupName;
  final String dateLabel;
  final String dateKey;
  final String shiftLabel;
  final bool isDayShift;
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
