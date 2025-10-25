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

enum TERateType { fpr, spr, rr }

class TEStatusTable extends StatelessWidget {
  const TEStatusTable({
    super.key,
    required this.controllerTag,
    required this.onRateTap,
  });

  final String controllerTag;
  final void Function(String rowKey, TERateType type) onRateTap;

  static const List<_ColumnDef> _columns = [
    _ColumnDef('#', minWidth: 72, flex: 0.6),
    _ColumnDef('MODEL NAME', minWidth: 260, flex: 2.8),
    _ColumnDef('GROUP NAME', minWidth: 220, flex: 2.0),
    _ColumnDef('WIP QTY', minWidth: 120, flex: 1.1),
    _ColumnDef('INPUT', minWidth: 120, flex: 1.1),
    _ColumnDef('FIRST FAIL', minWidth: 130, flex: 1.2),
    _ColumnDef('REPAIR QTY', minWidth: 130, flex: 1.2),
    _ColumnDef('FIRST PASS', minWidth: 130, flex: 1.2),
    _ColumnDef('REPAIR PASS', minWidth: 130, flex: 1.2),
    _ColumnDef('PASS', minWidth: 120, flex: 1.1),
    _ColumnDef('TOTAL PASS', minWidth: 130, flex: 1.2),
    _ColumnDef('F.P.R', minWidth: 130, flex: 1.2),
    _ColumnDef('S.P.R', minWidth: 130, flex: 1.2),
    _ColumnDef('R.R', minWidth: 130, flex: 1.2),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaWidth = MediaQuery.of(context).size.width;
        final availableWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : mediaWidth;
        final totalMinWidth = _columns.fold<double>(0, (sum, column) => sum + column.minWidth);
        final targetWidth = math.max(availableWidth, totalMinWidth);
        final extraWidth = math.max(0, targetWidth - totalMinWidth);
        final totalFlex = _columns.fold<double>(0, (sum, column) => sum + column.flex);
        final widths = _columns
            .map((column) => column.minWidth +
                (totalFlex == 0 ? 0 : extraWidth * (column.flex / totalFlex)))
            .toList(growable: false);

        return Container(
          decoration: BoxDecoration(
            color: _rowBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _tableBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: targetWidth),
                    child: Column(
                      children: [
                        _TableHeader(
                          columns: _columns,
                          columnWidths: widths,
                        ),
                        GetBuilder<TEManagementController>(
                          tag: controllerTag,
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
                            var rowCounter = 0;
                            for (final group in groups) {
                              for (var i = 0; i < group.rowKeys.length; i++) {
                                final rowKey = group.rowKeys[i];
                                final isFirst = i == 0;
                                final displayIndex = isFirst ? groupIndex.toString() : '';
                                final displayModel = isFirst ? group.modelName : '';
                                final isAlt = rowCounter % 2 == 1;
                                rowCounter++;

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
                                        columnWidths: widths,
                                        indexLabel: displayIndex,
                                        modelLabel: displayModel,
                                        row: row,
                                        rowKey: rowKey,
                                        isAlt: isAlt,
                                        lastUpdated: updatedAt,
                                        onRateTap: onRateTap,
                                      );
                                    },
                                  ),
                                );
                              }
                              groupIndex++;
                            }

                            return Column(children: rows);
                          },
                        ),
                      ],
                    ),
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
      height: 48,
      decoration: const BoxDecoration(color: _headerBg),
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

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.columnWidths,
    required this.indexLabel,
    required this.modelLabel,
    required this.row,
    required this.rowKey,
    required this.isAlt,
    required this.lastUpdated,
    required this.onRateTap,
  });

  final List<double> columnWidths;
  final String indexLabel;
  final String modelLabel;
  final TEReportRowEntity row;
  final String rowKey;
  final bool isAlt;
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
        return Container(
          height: _rowHeight,
          color: color,
          child: Row(children: _buildCells()),
        );
      },
    );
  }

  List<Widget> _buildCells() {
    final widths = columnWidths;
    var columnIndex = 0;
    final cells = <Widget>[];
    cells.add(_ValueCell(
      width: widths[columnIndex++],
      value: indexLabel,
      tooltip: indexLabel,
    ));
    cells.add(_ValueCell(
      width: widths[columnIndex++],
      value: modelLabel,
      tooltip: modelLabel,
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
