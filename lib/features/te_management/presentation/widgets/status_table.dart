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
const Color _dangerRed = Color(0xFFE6717C);
const Color _warningAmber = Color(0xFFFFDA6A);
const Color _successGreen = Color(0xFF4CAF50);
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
        final double resolvedTableWidth = math.min(maxWidth, targetWidth);
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

              final rows = <Widget>[];
              var groupIndex = 1;
              for (final group in groups) {
                rows.add(
                  _TableGroupBlock(
                    controllerTag: widget.controllerTag,
                    columnWidths: widths,
                    group: group,
                    groupIndex: groupIndex,
                    onRateTap: widget.onRateTap,
                  ),
                );
                groupIndex++;
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows,
              );
            },
          );
        }

        final header = SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            width: targetWidth,
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
                width: targetWidth,
                child: buildBody(),
              ),
            ),
          ),
        );

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: resolvedTableWidth,
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
          bottom: BorderSide(color: _tableBorder, width: 1),
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

class _TableGroupBlock extends StatelessWidget {
  const _TableGroupBlock({
    required this.controllerTag,
    required this.columnWidths,
    required this.group,
    required this.groupIndex,
    required this.onRateTap,
  });

  final String controllerTag;
  final List<double> columnWidths;
  final TEGroupedRows group;
  final int groupIndex;
  final void Function(String rowKey, TERateType type) onRateTap;

  @override
  Widget build(BuildContext context) {
    if (group.rowKeys.isEmpty) {
      return const SizedBox.shrink();
    }

    final isAltGroup = groupIndex.isOdd;

    final rows = <Widget>[];
    for (var i = 0; i < group.rowKeys.length; i++) {
      final rowKey = group.rowKeys[i];
      final isFirst = i == 0;
      final isLast = i == group.rowKeys.length - 1;

      rows.add(
        GetBuilder<TEManagementController>(
          tag: controllerTag,
          id: 'row_$rowKey',
          builder: (rowCtrl) {
            final row = rowCtrl.rowByKey(rowKey);
            if (row == null) {
              return const SizedBox.shrink();
            }
            final updatedAt = rowCtrl.rowLastUpdated(rowKey);
            return _TableRow(
              columnWidths: columnWidths,
              indexLabel: isFirst ? groupIndex.toString() : '',
              modelLabel: isFirst ? group.modelName : '',
              row: row,
              rowKey: rowKey,
              isAlt: isAltGroup,
              isFirstInGroup: isFirst,
              isLastInGroup: isLast,
              groupSize: group.rowKeys.length,
              groupRowIndex: i,
              lastUpdated: updatedAt,
              onRateTap: onRateTap,
            );
          },
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.columnWidths,
    required this.indexLabel,
    required this.modelLabel,
    required this.row,
    required this.rowKey,
    required this.isAlt,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.groupSize,
    required this.groupRowIndex,
    required this.lastUpdated,
    required this.onRateTap,
  });

  final List<double> columnWidths;
  final String indexLabel;
  final String modelLabel;
  final TEReportRowEntity row;
  final String rowKey;
  final bool isAlt;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final int groupSize;
  final int groupRowIndex;
  final DateTime? lastUpdated;
  final void Function(String rowKey, TERateType type) onRateTap;

  @override
  Widget build(BuildContext context) {
    final background = isAlt ? _rowAltBg : _rowBg;
    final highlight = lastUpdated != null &&
        DateTime.now().difference(lastUpdated!).inSeconds < 5;
    return TweenAnimationBuilder<Color?>(
      key: ValueKey(row.hashCode),
      tween: ColorTween(
        begin: highlight ? _highlight : background,
        end: background,
      ),
      duration: const Duration(milliseconds: 600),
      builder: (context, color, child) {
        final resolvedColor = color ?? background;
        return Container(
          height: _rowHeight,
          color: resolvedColor,
          child: Row(children: _buildCells(resolvedColor)),
        );
      },
    );
  }

  List<Widget> _buildCells(Color backgroundColor) {
    final widths = columnWidths;
    var columnIndex = 0;
    final cells = <Widget>[];
    cells.add(_MergedCell(
      width: widths[columnIndex++],
      value: indexLabel,
      tooltip: indexLabel,
      isFirst: isFirstInGroup,
      isLast: isLastInGroup,
      isLeading: true,
      background: backgroundColor,
      span: groupSize,
      rowIndex: groupRowIndex,
    ));
    cells.add(_MergedCell(
      width: widths[columnIndex++],
      value: modelLabel,
      tooltip: modelLabel,
      isFirst: isFirstInGroup,
      isLast: isLastInGroup,
      isLeading: false,
      background: backgroundColor,
      span: groupSize,
      rowIndex: groupRowIndex,
    ));
    cells.add(_ValueCell(
      width: widths[columnIndex++],
      value: row.groupName,
      tooltip: row.groupName,
    ));

    cells.addAll([
      _numericCell(widths[columnIndex++], row.wipQty),
      _numericCell(widths[columnIndex++], row.input),
      _numericCell(widths[columnIndex++], row.firstFail),
      _numericCell(widths[columnIndex++], row.repairQty),
      _numericCell(widths[columnIndex++], row.firstPass),
      _numericCell(widths[columnIndex++], row.repairPass),
      _numericCell(widths[columnIndex++], row.pass),
      _numericCell(widths[columnIndex++], row.totalPass),
      _rateCell(widths[columnIndex++], row.fpr, TERateType.fpr),
      _rateCell(widths[columnIndex++], row.spr, TERateType.spr),
      _rateCell(widths[columnIndex++], row.rr, TERateType.rr),
    ]);

    return cells;
  }

  Widget _numericCell(double width, num value) {
    final display = value.toString();
    return _ValueCell(
      width: width,
      value: display,
      tooltip: display,
    );
  }

  Widget _rateCell(double width, double value, TERateType type) {
    final style = _rateStyle(type, value);
    final text = '${value.toStringAsFixed(2)}%';
    return GestureDetector(
      onTap: () => onRateTap(rowKey, type),
      child: Container(
        width: width,
        height: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: _tableBorder, width: 1),
            bottom: BorderSide(color: _tableBorder, width: 1),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
  }

  _RateStyle _rateStyle(TERateType type, double value) {
    switch (type) {
      case TERateType.fpr:
      case TERateType.spr:
        if (value <= 90) {
          return const _RateStyle(_dangerRed, Colors.white);
        }
        if (value > 90 && value <= 97) {
          return const _RateStyle(_warningAmber, Colors.black87);
        }
        return const _RateStyle(_successGreen, Colors.white);
      case TERateType.rr:
        if (value >= 5) {
          return const _RateStyle(_dangerRed, Colors.white);
        }
        if (value > 2 && value < 5) {
          return const _RateStyle(_warningAmber, Colors.black87);
        }
        return const _RateStyle(_successGreen, Colors.white);
    }
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({
    required this.width,
    required this.value,
    this.tooltip,
  });

  final double width;
  final String value;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final text = value.isEmpty ? '-' : value;
    final tip = (tooltip ?? value).isEmpty ? '-' : (tooltip ?? value);
    return Container(
      width: width,
      height: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: _tableBorder, width: 1),
          bottom: BorderSide(color: _tableBorder, width: 1),
        ),
      ),
      child: Tooltip(
        message: tip,
        waitDuration: const Duration(milliseconds: 200),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: text == '-' ? _textMuted : _textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MergedCell extends StatelessWidget {
  const _MergedCell({
    required this.width,
    required this.value,
    required this.tooltip,
    required this.isFirst,
    required this.isLast,
    required this.isLeading,
    required this.background,
    required this.span,
    required this.rowIndex,
  });

  final double width;
  final String value;
  final String tooltip;
  final bool isFirst;
  final bool isLast;
  final bool isLeading;
  final Color background;
  final int span;
  final int rowIndex;

  @override
  Widget build(BuildContext context) {
    final showContent = rowIndex == 0 && value.isNotEmpty;
    final display = value.isEmpty ? '-' : value;
    final message = tooltip.isEmpty ? '-' : tooltip;

    return Container(
      width: width,
      height: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: showContent ? background : Colors.transparent,
        border: Border(
          left: isLeading
              ? const BorderSide(color: _tableBorder, width: 1)
              : BorderSide.none,
          right: const BorderSide(color: _tableBorder, width: 1),
          top: isFirst
              ? const BorderSide(color: _tableBorder, width: 1)
              : BorderSide.none,
          bottom: isLast
              ? const BorderSide(color: _tableBorder, width: 1)
              : BorderSide.none,
        ),
      ),
      child: showContent
          ? Tooltip(
              message: message,
              waitDuration: const Duration(milliseconds: 200),
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: _rowHeight * span,
                maxHeight: _rowHeight * span,
                child: SizedBox(
                  height: _rowHeight * span,
                  child: Center(
                    child: Text(
                      display,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: display == '-' ? _textMuted : _textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
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
