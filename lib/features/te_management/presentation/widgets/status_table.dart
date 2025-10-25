import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/te_report.dart';
import '../controllers/te_management_controller.dart';

const Color _tableBorder = Color(0xFF1F3A5F);
const Color _headerBg = Color(0xFF0C2748);
const Color _rowBg = Color(0xFF10213A);
const Color _rowAltBg = Color(0xFF0D1B30);
const Color _textPrimary = Color(0xFFE2E8F0);
const Color _textMuted = Color(0xFF9AB3CF);
const Color _accentCyan = Color(0xFF22D3EE);
const Color _dangerRed = Color(0xFFE6717C);
const Color _warningAmber = Color(0xFFFFDA6A);
const Color _successGreen = Color(0xFF4CAF50);
const Color _highlight = Color(0x3322D3EE);

enum TERateType { fpr, spr, rr }

class TEStatusTable extends StatelessWidget {
  const TEStatusTable({
    super.key,
    required this.controllerTag,
    required this.onRateTap,
  });

  final String controllerTag;
  final void Function(String rowKey, TERateType type) onRateTap;

  static const double _rowHeight = 48;
  static const List<_ColumnDef> _columns = [
    _ColumnDef(label: '#', width: 64, alignment: Alignment.center),
    _ColumnDef(label: 'MODEL NAME', width: 220, alignment: Alignment.centerLeft),
    _ColumnDef(label: 'GROUP NAME', width: 220, alignment: Alignment.centerLeft),
    _ColumnDef(label: 'WIP QTY', width: 110),
    _ColumnDef(label: 'INPUT', width: 110),
    _ColumnDef(label: 'FIRST FAIL', width: 120),
    _ColumnDef(label: 'REPAIR QTY', width: 120),
    _ColumnDef(label: 'FIRST PASS', width: 120),
    _ColumnDef(label: 'REPAIR PASS', width: 130),
    _ColumnDef(label: 'PASS', width: 110),
    _ColumnDef(label: 'TOTAL PASS', width: 130),
    _ColumnDef(label: 'F.P.R', width: 110),
    _ColumnDef(label: 'S.P.R', width: 110),
    _ColumnDef(label: 'R.R', width: 100),
  ];

  double get _tableWidth =>
      _columns.fold<double>(0, (previousValue, column) => previousValue + column.width);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _rowBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _tableBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Scrollbar(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: _tableWidth),
                child: Column(
                  children: [
                    _TableHeader(columns: _columns),
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
                                    columns: _columns,
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
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.columns});

  final List<_ColumnDef> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(color: _headerBg),
      child: Row(
        children: columns
            .map(
              (column) => _HeaderCell(
                label: column.label,
                width: column.width,
                alignment: column.alignment,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.width,
    required this.alignment,
  });

  final String label;
  final double width;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: double.infinity,
      alignment: alignment,
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
    required this.columns,
    required this.indexLabel,
    required this.modelLabel,
    required this.row,
    required this.rowKey,
    required this.isAlt,
    required this.lastUpdated,
    required this.onRateTap,
  });

  final List<_ColumnDef> columns;
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
    final cells = <Widget>[];
    cells.add(_ValueCell(
      width: columns[0].width,
      alignment: Alignment.center,
      value: indexLabel,
      tooltip: indexLabel,
    ));
    cells.add(_ValueCell(
      width: columns[1].width,
      alignment: Alignment.centerLeft,
      value: modelLabel,
      tooltip: modelLabel,
    ));
    cells.add(_ValueCell(
      width: columns[2].width,
      alignment: Alignment.centerLeft,
      value: row.groupName,
      tooltip: row.groupName,
    ));
    cells.addAll([
      _numericCell(columns[3], row.wipQty),
      _numericCell(columns[4], row.input),
      _numericCell(columns[5], row.firstFail),
      _numericCell(columns[6], row.repairQty),
      _numericCell(columns[7], row.firstPass),
      _numericCell(columns[8], row.repairPass),
      _numericCell(columns[9], row.pass),
      _numericCell(columns[10], row.totalPass),
      _rateCell(columns[11], row.fpr, TERateType.fpr),
      _rateCell(columns[12], row.spr, TERateType.spr),
      _rateCell(columns[13], row.rr, TERateType.rr),
    ]);
    return cells;
  }

  Widget _numericCell(_ColumnDef def, num value) {
    return _ValueCell(
      width: def.width,
      alignment: Alignment.center,
      value: value.toStringAsFixed(0),
      tooltip: value.toStringAsFixed(0),
    );
  }

  Widget _rateCell(_ColumnDef def, double value, TERateType type) {
    final style = _rateStyle(type, value);
    final text = '${value.toStringAsFixed(2)}%';
    return GestureDetector(
      onTap: () => onRateTap(rowKey, type),
      child: Container(
        width: def.width,
        height: double.infinity,
        alignment: def.alignment,
        padding: def.padding,
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
    required this.alignment,
    required this.value,
    this.tooltip,
  });

  final double width;
  final Alignment alignment;
  final String value;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: double.infinity,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: _tableBorder, width: 1),
          bottom: BorderSide(color: _tableBorder, width: 1),
        ),
      ),
      child: Tooltip(
        message: (tooltip ?? value).isEmpty ? 'N/A' : (tooltip ?? value),
        waitDuration: const Duration(milliseconds: 200),
        child: Text(
          value.isEmpty ? '-' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: value.isEmpty ? _textMuted : _textPrimary,
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
  const _ColumnDef({
    required this.label,
    required this.width,
    this.alignment = Alignment.center,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final String label;
  final double width;
  final Alignment alignment;
  final EdgeInsets padding;
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
      child: const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(_accentCyan)),
    );
  }
}
