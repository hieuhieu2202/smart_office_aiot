import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/te_report.dart';
import '../controllers/te_management_controller.dart';

const Color _tableBorder = Color(0xFF15437A);
const Color _headerBg = Color(0xFF062B55);
const Color _rowBg = Color(0xFF082F62);
const Color _rowAltBg = Color(0xFF073456);
const Color _textPrimary = Color(0xFFE2E8F0);
const Color _textMuted = Color(0xFF9AB3CF);
const Color _accentCyan = Color(0xFF22D3EE);
const Color _dangerRed = Color(0xFFEF4444);
const Color _warningAmber = Color(0xFFF59E0B);
const Color _successGreen = Color(0xFF22C55E);
const Color _highlight = Color(0x332B7FFF);
const double _rowHeight = 48;
const double _headerHeight = 48;

enum TERateType { fpr, spr, rr }

class TEStatusTable extends StatefulWidget {
  const TEStatusTable({
    super.key,
    required this.controllerTag,
    required this.onRateTap,
  });

  final String controllerTag;
  final void Function(String rowKey, TERateType type) onRateTap;

  static const List<_ColumnDef> _columns = [
    _ColumnDef('#', minWidth: 60, flex: 0.6),
    _ColumnDef('MODEL NAME', minWidth: 220, flex: 2.6),
    _ColumnDef('GROUP NAME', minWidth: 180, flex: 1.9),
    _ColumnDef('WIP QTY', minWidth: 100, flex: 1.0),
    _ColumnDef('INPUT', minWidth: 100, flex: 1.0),
    _ColumnDef('FIRST FAIL', minWidth: 110, flex: 1.1),
    _ColumnDef('REPAIR QTY', minWidth: 110, flex: 1.1),
    _ColumnDef('FIRST PASS', minWidth: 110, flex: 1.1),
    _ColumnDef('REPAIR PASS', minWidth: 110, flex: 1.1),
    _ColumnDef('PASS', minWidth: 100, flex: 1.0),
    _ColumnDef('TOTAL PASS', minWidth: 110, flex: 1.1),
    _ColumnDef('F.P.R', minWidth: 110, flex: 1.1),
    _ColumnDef('S.P.R', minWidth: 110, flex: 1.1),
    _ColumnDef('R.R', minWidth: 110, flex: 1.1),
  ];

  @override
  State<TEStatusTable> createState() => _TEStatusTableState();
}

class _TEStatusTableState extends State<TEStatusTable> {
  late final ScrollController _horizontalController;
  late final ScrollController _verticalController;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaWidth = MediaQuery.of(context).size.width;
        final availableWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : mediaWidth;
        final totalMinWidth = TEStatusTable._columns
            .fold<double>(0, (sum, column) => sum + column.minWidth);
        final maxWidth = availableWidth <= 0 ? totalMinWidth : availableWidth;
        final bool canExpand = maxWidth > totalMinWidth;
        final double targetWidth = canExpand ? maxWidth : totalMinWidth;
        final double resolvedTableWidth = math.max(totalMinWidth, targetWidth);
        final extraWidth = math.max(0, targetWidth - totalMinWidth);
        final totalFlex = TEStatusTable._columns
            .fold<double>(0, (sum, column) => sum + column.flex);
        final widths = TEStatusTable._columns
            .map((column) => column.minWidth +
                (totalFlex == 0 ? 0 : extraWidth * (column.flex / totalFlex)))
            .toList(growable: false);

        Widget buildBody() {
          return GetBuilder<TEManagementController>(
            tag: widget.controllerTag,
            id: 'table',
            builder: (ctrl) {
              final groups = ctrl.visibleGroups;
              if (groups.isEmpty) {
                if (ctrl.isLoading.value) {
                  return const _TableLoadingPlaceholder();
                }
                return const _TableEmptyState();
              }

              final now = DateTime.now();
              final blocks = <Widget>[];
              var groupIndex = 1;
              for (final group in groups) {
                final rowKeys = group.rowKeys;
                if (rowKeys.isEmpty) {
                  groupIndex++;
                  continue;
                }

                final rows = <_RowRenderData>[];
                final baseColor = groupIndex.isOdd ? _rowBg : _rowAltBg;
                for (final key in rowKeys) {
                  final row = ctrl.rowByKey(key);
                  if (row == null) continue;
                  final updatedAt = ctrl.rowLastUpdated(key);
                  final highlight = updatedAt != null &&
                      now.difference(updatedAt).inMilliseconds < 1200;
                  rows.add(
                    _RowRenderData(
                      rowKey: key,
                      entity: row,
                      baseColor: baseColor,
                      shouldHighlight: highlight,
                    ),
                  );
                }

                if (rows.isEmpty) {
                  groupIndex++;
                  continue;
                }

                blocks.add(
                  _GroupTable(
                    columnWidths: widths,
                    groupIndex: groupIndex,
                    modelName: group.modelName,
                    rows: rows,
                    onRateTap: widget.onRateTap,
                  ),
                );
                groupIndex++;
              }

              if (blocks.isEmpty) {
                return const _TableEmptyState();
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: blocks,
              );
            },
          );
        }

        final header = SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            width: resolvedTableWidth,
            child: _TableHeader(
              columns: TEStatusTable._columns,
              columnWidths: widths,
            ),
          ),
        );

        final body = Scrollbar(
          controller: _verticalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalController,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: resolvedTableWidth,
                child: buildBody(),
              ),
            ),
          ),
        );

        return Align(
          alignment: Alignment.topCenter,
          child: Container(
            decoration: BoxDecoration(
              color: _rowBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _tableBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(
                    top: _headerHeight,
                    child: body,
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: header,
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

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.columns,
    required this.columnWidths,
  });

  final List<_ColumnDef> columns;
  final List<double> columnWidths;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _headerHeight,
      decoration: const BoxDecoration(
        color: _headerBg,
        border: Border(
          bottom: BorderSide(color: _tableBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < columns.length; i++)
            _HeaderCell(label: columns[i].label, width: columnWidths[i]),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.width,
  });

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: _tableBorder, width: 1),
        ),
      ),
      child: Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 200),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _GroupTable extends StatelessWidget {
  const _GroupTable({
    required this.columnWidths,
    required this.groupIndex,
    required this.modelName,
    required this.rows,
    required this.onRateTap,
  });

  final List<double> columnWidths;
  final int groupIndex;
  final String modelName;
  final List<_RowRenderData> rows;
  final void Function(String rowKey, TERateType type) onRateTap;

  @override
  Widget build(BuildContext context) {
    final totalHeight = rows.length * _rowHeight;
    final indexText = groupIndex.toString();
    final modelText = modelName.isEmpty ? '-' : modelName;
    final spanHighlight = rows.any((row) => row.shouldHighlight);
    final baseColor = rows.first.baseColor;

    final children = <Widget>[];
    var columnIndex = 0;

    children.add(
      _SpanCell(
        width: columnWidths[columnIndex++],
        label: indexText,
        tooltip: indexText,
        span: rows.length,
        baseColor: baseColor,
        shouldHighlight: spanHighlight,
        addLeftBorder: true,
      ),
    );

    children.add(
      _SpanCell(
        width: columnWidths[columnIndex++],
        label: modelText,
        tooltip: modelText,
        span: rows.length,
        baseColor: baseColor,
        shouldHighlight: spanHighlight,
      ),
    );

    children.add(
      _ValueColumn(
        width: columnWidths[columnIndex++],
        rows: rows,
        textBuilder: (row) => row.entity.groupName,
        tooltipBuilder: (row) => row.entity.groupName,
        textAlign: TextAlign.center,
        addLeftBorder: true,
        showLeadingDot: true,
      ),
    );

    children.addAll([
      _ValueColumn(
        width: columnWidths[columnIndex++],
        rows: rows,
        textBuilder: (row) => row.entity.wipQty.toString(),
        textAlign: TextAlign.center,
      ),
      _ValueColumn(
        width: columnWidths[columnIndex++],
        rows: rows,
        textBuilder: (row) => row.entity.input.toString(),
        textAlign: TextAlign.center,
      ),
      _ValueColumn(
        width: columnWidths[columnIndex++],
        rows: rows,
        textBuilder: (row) => row.entity.firstFail.toString(),
        textAlign: TextAlign.center,
      ),
      _ValueColumn(
        width: columnWidths[columnIndex++],
        rows: rows,
        textBuilder: (row) => row.entity.repairQty.toString(),
        textAlign: TextAlign.center,
      ),
      _ValueColumn(
        width: columnWidths[columnIndex++],
        rows: rows,
        textBuilder: (row) => row.entity.firstPass.toString(),
        textAlign: TextAlign.center,
      ),
      _ValueColumn(
        width: columnWidths[columnIndex++],
        rows: rows,
        textBuilder: (row) => row.entity.repairPass.toString(),
        textAlign: TextAlign.center,
      ),
      _ValueColumn(
        width: columnWidths[columnIndex++],
        rows: rows,
        textBuilder: (row) => row.entity.pass.toString(),
        textAlign: TextAlign.center,
      ),
      _ValueColumn(
        width: columnWidths[columnIndex++],
        rows: rows,
        textBuilder: (row) => row.entity.totalPass.toString(),
        textAlign: TextAlign.center,
      ),
    ]);

    children.addAll([
      _RateColumn(
        width: columnWidths[columnIndex++],
        rows: rows,
        type: TERateType.fpr,
        onRateTap: onRateTap,
      ),
      _RateColumn(
        width: columnWidths[columnIndex++],
        rows: rows,
        type: TERateType.spr,
        onRateTap: onRateTap,
      ),
      _RateColumn(
        width: columnWidths[columnIndex++],
        rows: rows,
        type: TERateType.rr,
        onRateTap: onRateTap,
      ),
    ]);

    return SizedBox(
      height: totalHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SpanCell extends StatelessWidget {
  const _SpanCell({
    required this.width,
    required this.label,
    required this.tooltip,
    required this.span,
    required this.baseColor,
    required this.shouldHighlight,
    this.addLeftBorder = false,
  });

  final double width;
  final String label;
  final String tooltip;
  final int span;
  final Color baseColor;
  final bool shouldHighlight;
  final bool addLeftBorder;

  @override
  Widget build(BuildContext context) {
    final display = label.isEmpty ? '-' : label;
    final message = tooltip.isEmpty ? display : tooltip;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        begin: shouldHighlight ? _highlight : baseColor,
        end: baseColor,
      ),
      duration: const Duration(milliseconds: 600),
      builder: (context, color, child) {
        return Container(
          width: width,
          height: _rowHeight * span,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: color ?? baseColor,
            border: Border(
              left: addLeftBorder
                  ? const BorderSide(color: _tableBorder, width: 1)
                  : BorderSide.none,
              right: const BorderSide(color: _tableBorder, width: 1),
              top: const BorderSide(color: _tableBorder, width: 1),
              bottom: const BorderSide(color: _tableBorder, width: 1),
            ),
          ),
          child: Tooltip(
            message: message,
            waitDuration: const Duration(milliseconds: 200),
            child: Text(
              display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ValueColumn extends StatelessWidget {
  const _ValueColumn({
    required this.width,
    required this.rows,
    required this.textBuilder,
    this.tooltipBuilder,
    this.textAlign = TextAlign.center,
    this.addLeftBorder = false,
    this.showLeadingDot = false,
  });

  final double width;
  final List<_RowRenderData> rows;
  final String Function(_RowRenderData row) textBuilder;
  final String Function(_RowRenderData row)? tooltipBuilder;
  final TextAlign textAlign;
  final bool addLeftBorder;
  final bool showLeadingDot;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: rows.length * _rowHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++)
          _ValueCell(
            width: width,
            row: rows[i],
            display: textBuilder(rows[i]),
            tooltip: tooltipBuilder?.call(rows[i]) ?? textBuilder(rows[i]),
            textAlign: textAlign,
            isFirst: i == 0,
            isLast: i == rows.length - 1,
            addLeftBorder: addLeftBorder,
            showLeadingDot: showLeadingDot,
          ),
        ],
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({
    required this.width,
    required this.row,
    required this.display,
    required this.tooltip,
    required this.textAlign,
    required this.isFirst,
    required this.isLast,
    required this.addLeftBorder,
    required this.showLeadingDot,
  });

  final double width;
  final _RowRenderData row;
  final String display;
  final String tooltip;
  final TextAlign textAlign;
  final bool isFirst;
  final bool isLast;
  final bool addLeftBorder;
  final bool showLeadingDot;

  @override
  Widget build(BuildContext context) {
    final text = display.isEmpty ? '-' : display;
    final message = tooltip.isEmpty ? text : tooltip;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        begin: row.shouldHighlight ? _highlight : row.baseColor,
        end: row.baseColor,
      ),
      duration: const Duration(milliseconds: 600),
      builder: (context, color, child) {
        final textStyle = TextStyle(
          color: text == '-' ? _textMuted : _textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        );

        Widget buildContent() {
          if (showLeadingDot && text != '-') {
            return Text.rich(
              TextSpan(
                style: textStyle,
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _successGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  TextSpan(text: text),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
            );
          }

          return Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            style: textStyle,
          );
        }

        return Container(
          width: width,
          height: _rowHeight,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: color ?? row.baseColor,
            border: Border(
              left: addLeftBorder
                  ? const BorderSide(color: _tableBorder, width: 1)
                  : BorderSide.none,
              right: const BorderSide(color: _tableBorder, width: 1),
              top: isFirst
                  ? const BorderSide(color: _tableBorder, width: 1)
                  : BorderSide.none,
              bottom: const BorderSide(color: _tableBorder, width: 1),
            ),
          ),
          child: Tooltip(
            message: message,
            waitDuration: const Duration(milliseconds: 200),
            child: buildContent(),
          ),
        );
      },
    );
  }
}

class _RateColumn extends StatelessWidget {
  const _RateColumn({
    required this.width,
    required this.rows,
    required this.type,
    required this.onRateTap,
  });

  final double width;
  final List<_RowRenderData> rows;
  final TERateType type;
  final void Function(String rowKey, TERateType type) onRateTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: rows.length * _rowHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++)
            _RateCell(
              width: width,
              row: rows[i],
              type: type,
              isFirst: i == 0,
              isLast: i == rows.length - 1,
              onTap: () => onRateTap(rows[i].rowKey, type),
            ),
        ],
      ),
    );
  }
}

class _RateCell extends StatelessWidget {
  const _RateCell({
    required this.width,
    required this.row,
    required this.type,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final double width;
  final _RowRenderData row;
  final TERateType type;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final value = switch (type) {
      TERateType.fpr => row.entity.fpr,
      TERateType.spr => row.entity.spr,
      TERateType.rr => row.entity.rr,
    };
    final style = _rateStyle(type, value);
    final text = '${value.toStringAsFixed(2)}%';

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        begin: row.shouldHighlight ? _highlight : row.baseColor,
        end: row.baseColor,
      ),
      duration: const Duration(milliseconds: 600),
      builder: (context, color, child) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            height: _rowHeight,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: color ?? row.baseColor,
              border: Border(
                right: const BorderSide(color: _tableBorder, width: 1),
                top: isFirst
                    ? const BorderSide(color: _tableBorder, width: 1)
                    : BorderSide.none,
                bottom: const BorderSide(color: _tableBorder, width: 1),
              ),
            ),
            child: Tooltip(
              message: 'Tap to drill down',
              waitDuration: const Duration(milliseconds: 200),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: style.foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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

_RateStyle _rateStyle(TERateType type, double value) {
  switch (type) {
    case TERateType.fpr:
    case TERateType.spr:
      if (value <= 90) {
        return const _RateStyle(_dangerRed, Colors.white);
      }
      if (value > 90 && value <= 97) {
        return const _RateStyle(_warningAmber, Colors.white);
      }
      return const _RateStyle(_successGreen, Colors.white);
    case TERateType.rr:
      if (value >= 5) {
        return const _RateStyle(_dangerRed, Colors.white);
      }
      if (value > 2 && value < 5) {
        return const _RateStyle(_warningAmber, Colors.white);
      }
      return const _RateStyle(_successGreen, Colors.white);
  }
}

class _RowRenderData {
  const _RowRenderData({
    required this.rowKey,
    required this.entity,
    required this.baseColor,
    required this.shouldHighlight,
  });

  final String rowKey;
  final TEReportRowEntity entity;
  final Color baseColor;
  final bool shouldHighlight;
}

class _RateStyle {
  const _RateStyle(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

class _ColumnDef {
  const _ColumnDef(this.label, {required this.minWidth, required this.flex});

  final String label;
  final double minWidth;
  final double flex;
}

class _TableEmptyState extends StatelessWidget {
  const _TableEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _tableBorder, width: 1),
        ),
      ),
      child: const Text(
        'No data available',
        style: TextStyle(color: _textMuted, fontSize: 14),
      ),
    );
  }
}

class _TableLoadingPlaceholder extends StatelessWidget {
  const _TableLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _tableBorder, width: 1),
        ),
      ),
      child: const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(_accentCyan),
      ),
    );
  }
}
