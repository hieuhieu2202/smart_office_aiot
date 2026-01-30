import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../viewmodels/uph_tracking_view_state.dart';
import '../viewmodels/upd_tracking_view_state.dart';

const Color _tableBackground = Color(0xFF0F233F);
const Color _headerBackground = Color(0xFF17375E);
const Color _headerBorder = Color(0xFF2A4B7A);
const Color _rowBackground = Color(0xFF10253F);
const Color _gridBorder = Color(0xFF1C2F4A);
const Color _textPrimary = Colors.white;
const Color _textSecondary = Colors.white70;
const double _headerHeight = 56;
const double _subHeaderHeight = 36;
const double _rowHeight = 52;

class UphTrackingTable extends StatefulWidget {
  const UphTrackingTable({
    super.key,
    required this.view,
    required this.rows,
    this.onStationTap,
  });

  final UphTrackingViewState view;
  final List<UphTrackingRowView> rows;
  final void Function(UphTrackingRowView row)? onStationTap;

  @override
  State<UphTrackingTable> createState() => _UphTrackingTableState();
}

class _UphTrackingTableState extends State<UphTrackingTable> {
  static const double _modelWidth = 220;
  static const double _stationWidth = 160;
  static const double _metricWidth = 110;
  static const double _sectionWidth = 120;

  final ScrollController _horizontalCtrl = ScrollController();
  final ScrollController _verticalCtrl = ScrollController();

  @override
  void dispose() {
    _horizontalCtrl.dispose();
    _verticalCtrl.dispose();
    super.dispose();
  }

  double get _baseWidth =>
      _modelWidth + _stationWidth + (_metricWidth * 4); // WIP, PASS, UPH, LB

  double get _totalWidth =>
      _baseWidth + (widget.view.sections.length * 2 * _sectionWidth);

  @override
  Widget build(BuildContext context) {
    final sections = widget.view.sections;
    final rows = widget.rows;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (_rowHeight * math.max(rows.length, 1)) +
                _headerHeight +
                _subHeaderHeight +
                8;
        final double bodyHeight =
            (maxHeight - _headerHeight - _subHeaderHeight).clamp(160.0, double.infinity);

        return Container(
          decoration: BoxDecoration(
            color: _tableBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gridBorder.withOpacity(.6), width: 1.2),
          ),
          child: Scrollbar(
            controller: _horizontalCtrl,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalCtrl,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: _totalWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(sections),
                    SizedBox(
                      height: bodyHeight,
                      child: Scrollbar(
                        controller: _verticalCtrl,
                        thumbVisibility: true,
                        child: ListView.separated(
                          controller: _verticalCtrl,
                          padding: EdgeInsets.zero,
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 0,
                            thickness: 0.6,
                            color: _gridBorder,
                          ),
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            final bool showModels = index == 0;
                            return _buildRow(
                              row: row,
                              sections: sections,
                              modelsText: showModels ? widget.view.modelsText : '',
                              lineBalance: widget.view.lineBalance,
                              onStationTap: widget.onStationTap,
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
        );
      },
    );
  }

  Widget _buildHeader(List<String> sections) {
    final sectionHeaders = sections
        .map(
          (section) => Container(
            width: _sectionWidth * 2,
            height: _headerHeight,
            decoration: BoxDecoration(
              color: _headerBackground,
              border: Border(
                top: BorderSide(color: _headerBorder, width: 1.1),
                bottom: BorderSide(color: _headerBorder, width: 1.1),
                right: BorderSide(color: _headerBorder, width: 1.1),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              section,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ),
        )
        .toList();

    return Column(
      children: [
        Row(
          children: [
            _headerCell('MODEL', width: _modelWidth, spanTwoRows: true),
            _headerCell('STATION', width: _stationWidth, spanTwoRows: true),
            _headerCell('WIP', width: _metricWidth, spanTwoRows: true),
            _headerCell('PASS', width: _metricWidth, spanTwoRows: true),
            _headerCell('UPH', width: _metricWidth, spanTwoRows: true),
            _headerCell('LINE BALANCE', width: _metricWidth, spanTwoRows: true),
            ...sectionHeaders,
          ],
        ),
        Row(
          children: [
            SizedBox(width: _modelWidth + _stationWidth + (_metricWidth * 4)),
            for (int i = 0; i < sections.length; i++) ...[
              _subHeaderCell('PASS', width: _sectionWidth),
              _subHeaderCell('PRODUCTIVITY', width: _sectionWidth),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildRow({
    required UphTrackingRowView row,
    required List<String> sections,
    required String modelsText,
    required double lineBalance,
    required void Function(UphTrackingRowView row)? onStationTap,
  }) {
    final lineBalanceText = lineBalance <= 0
        ? '-'
        : '${lineBalance.toStringAsFixed(2)}%';

    return Container(
      height: _rowHeight,
      color: _rowBackground,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bodyCell(modelsText.isEmpty ? '' : modelsText,
              width: _modelWidth, textAlign: TextAlign.left, padding: const EdgeInsets.symmetric(horizontal: 12)),
          _clickableCell(
            row.station,
            width: _stationWidth,
            onTap: onStationTap == null ? null : () => onStationTap(row),
          ),
          _metricCell('${row.wip}', width: _metricWidth, color: Colors.cyanAccent),
          _metricCell('${row.totalPass}',
              width: _metricWidth,
              color: row.totalPass > 0 ? const Color(0xFF38D893) : _textSecondary,
              onTap: onStationTap == null ? null : () => onStationTap(row)),
          _metricCell(
            row.uph <= 0 ? '-' : row.uph.toStringAsFixed(2),
            width: _metricWidth,
            color: row.uph > 0 ? const Color(0xFFFFC56F) : _textSecondary,
            onTap: onStationTap == null ? null : () => onStationTap(row),
          ),
          _metricCell(lineBalanceText,
              width: _metricWidth, color: const Color(0xFF42A0FF)),
          for (int i = 0; i < sections.length; i++) ...[
            _seriesCell(row.passSeries, i,
                width: _sectionWidth,
                formatter: (value) => value <= 0 ? '0' : value.round().toString(),
                colorBuilder: (value) =>
                    value > 0 ? const Color(0xFF38D893) : _textSecondary),
            _seriesCell(row.productivitySeries, i,
                width: _sectionWidth,
                formatter: (value) => value <= 0
                    ? '0%'
                    : '${value.toStringAsFixed(1)}%',
                colorBuilder: _productivityColor,
                backgroundBuilder: _productivityBackground),
          ],
        ],
      ),
    );
  }
}

class UpdTrackingTable extends StatefulWidget {
  const UpdTrackingTable({
    super.key,
    required this.view,
    required this.rows,
    this.onStationTap,
  });

  final UpdTrackingViewState view;
  final List<UpdTrackingRowView> rows;
  final void Function(UpdTrackingRowView row)? onStationTap;

  @override
  State<UpdTrackingTable> createState() => _UpdTrackingTableState();
}

class _UpdTrackingTableState extends State<UpdTrackingTable> {
  static const double _modelWidth = 220;
  static const double _stationWidth = 160;
  static const double _metricWidth = 110;
  static const double _sectionWidth = 120;

  final ScrollController _horizontalCtrl = ScrollController();
  final ScrollController _verticalCtrl = ScrollController();

  @override
  void dispose() {
    _horizontalCtrl.dispose();
    _verticalCtrl.dispose();
    super.dispose();
  }

  double get _baseWidth =>
      _modelWidth + _stationWidth + (_metricWidth * 3); // WIP, PASS, UPD

  double get _totalWidth =>
      _baseWidth + (widget.view.dates.length * 2 * _sectionWidth);

  @override
  Widget build(BuildContext context) {
    final dates = widget.view.dates;
    final rows = widget.rows;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (_rowHeight * math.max(rows.length, 1)) +
                _headerHeight +
                _subHeaderHeight +
                8;
        final double bodyHeight =
            (maxHeight - _headerHeight - _subHeaderHeight).clamp(160.0, double.infinity);

        return Container(
          decoration: BoxDecoration(
            color: _tableBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gridBorder.withOpacity(.6), width: 1.2),
          ),
          child: Scrollbar(
            controller: _horizontalCtrl,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalCtrl,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: _totalWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(dates),
                    SizedBox(
                      height: bodyHeight,
                      child: Scrollbar(
                        controller: _verticalCtrl,
                        thumbVisibility: true,
                        child: ListView.separated(
                          controller: _verticalCtrl,
                          padding: EdgeInsets.zero,
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 0,
                            thickness: 0.6,
                            color: _gridBorder,
                          ),
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            final bool showModels = index == 0;
                            return _buildRow(
                              row: row,
                              dates: dates,
                              modelsText: showModels ? widget.view.modelsText : '',
                              onStationTap: widget.onStationTap,
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
        );
      },
    );
  }

  Widget _buildHeader(List<String> dates) {
    final dateHeaders = dates
        .map(
          (date) => Container(
            width: _sectionWidth * 2,
            height: _headerHeight,
            decoration: BoxDecoration(
              color: _headerBackground,
              border: Border(
                top: BorderSide(color: _headerBorder, width: 1.1),
                bottom: BorderSide(color: _headerBorder, width: 1.1),
                right: BorderSide(color: _headerBorder, width: 1.1),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              date,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ),
        )
        .toList();

    return Column(
      children: [
        Row(
          children: [
            _headerCell('MODEL', width: _modelWidth, spanTwoRows: true),
            _headerCell('STATION', width: _stationWidth, spanTwoRows: true),
            _headerCell('WIP', width: _metricWidth, spanTwoRows: true),
            _headerCell('PASS', width: _metricWidth, spanTwoRows: true),
            _headerCell('UPD', width: _metricWidth, spanTwoRows: true),
            ...dateHeaders,
          ],
        ),
        Row(
          children: [
            SizedBox(width: _modelWidth + _stationWidth + (_metricWidth * 3)),
            for (int i = 0; i < dates.length; i++) ...[
              _subHeaderCell('PASS', width: _sectionWidth),
              _subHeaderCell('PRODUCTIVITY', width: _sectionWidth),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildRow({
    required UpdTrackingRowView row,
    required List<String> dates,
    required String modelsText,
    required void Function(UpdTrackingRowView row)? onStationTap,
  }) {
    return Container(
      height: _rowHeight,
      color: _rowBackground,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bodyCell(modelsText.isEmpty ? '' : modelsText,
              width: _modelWidth, textAlign: TextAlign.left, padding: const EdgeInsets.symmetric(horizontal: 12)),
          _clickableCell(
            row.station,
            width: _stationWidth,
            onTap: onStationTap == null ? null : () => onStationTap(row),
          ),
          _metricCell('${row.wip}', width: _metricWidth, color: Colors.cyanAccent),
          _metricCell('${row.totalPass}',
              width: _metricWidth,
              color: row.totalPass > 0 ? const Color(0xFF38D893) : _textSecondary,
              onTap: onStationTap == null ? null : () => onStationTap(row)),
          _metricCell(
            row.upd <= 0 ? '-' : row.upd.toStringAsFixed(2),
            width: _metricWidth,
            color: row.upd > 0 ? const Color(0xFFFFC56F) : _textSecondary,
            onTap: onStationTap == null ? null : () => onStationTap(row),
          ),
          for (int i = 0; i < dates.length; i++) ...[
            _seriesCell(row.passSeries, i,
                width: _sectionWidth,
                formatter: (value) => value <= 0 ? '0' : value.round().toString(),
                colorBuilder: (value) =>
                    value > 0 ? const Color(0xFF38D893) : _textSecondary),
            _seriesCell(row.productivitySeries, i,
                width: _sectionWidth,
                formatter: (value) => value <= 0
                    ? '0%'
                    : '${value.toStringAsFixed(1)}%',
                colorBuilder: _productivityColor,
                backgroundBuilder: _productivityBackground),
          ],
        ],
      ),
    );
  }
}

Widget _headerCell(String label,
    {required double width, bool spanTwoRows = false}) {
  return Container(
    width: width,
    height: spanTwoRows ? (_headerHeight * 1.0 + _subHeaderHeight) : _headerHeight,
    decoration: BoxDecoration(
      color: _headerBackground,
      border: Border(
        top: BorderSide(color: _headerBorder, width: 1.1),
        left: BorderSide(color: _headerBorder, width: 1.1),
        right: BorderSide(color: _headerBorder, width: 1.1),
        bottom: BorderSide(color: _headerBorder, width: 1.1),
      ),
    ),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
      ),
    ),
  );
}

Widget _subHeaderCell(String label, {required double width}) {
  return Container(
    width: width,
    height: _subHeaderHeight,
    decoration: const BoxDecoration(
      color: _headerBackground,
      border: Border(
        left: BorderSide(color: _headerBorder, width: 1.1),
        right: BorderSide(color: _headerBorder, width: 1.1),
        bottom: BorderSide(color: _headerBorder, width: 1.1),
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
    ),
  );
}

Widget _bodyCell(
  String text, {
  required double width,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 8),
  TextAlign textAlign = TextAlign.center,
}) {
  Alignment alignment;
  switch (textAlign) {
    case TextAlign.center:
      alignment = Alignment.center;
      break;
    case TextAlign.right:
      alignment = Alignment.centerRight;
      break;
    default:
      alignment = Alignment.centerLeft;
  }

  return Container(
    width: width,
    padding: padding,
    alignment: alignment,
    child: Text(
      text,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _textSecondary,
      ),
    ),
  );
}

Widget _clickableCell(
  String text, {
  required double width,
  VoidCallback? onTap,
}) {
  final cell = Container(
    width: width,
    alignment: Alignment.center,
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
      ),
    ),
  );

  if (onTap == null) return cell;

  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: cell,
    ),
  );
}

Widget _metricCell(
  String text, {
  required double width,
  Color color = _textPrimary,
  VoidCallback? onTap,
}) {
  final label = Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: color,
    ),
  );

  final cell = Container(
    width: width,
    alignment: Alignment.center,
    child: label,
  );

  if (onTap == null) return cell;

  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: cell,
    ),
  );
}

Widget _seriesCell(
  List<double> values,
  int index, {
  required double width,
  required String Function(double value) formatter,
  required Color Function(double value) colorBuilder,
  Color? Function(double value)? backgroundBuilder,
}) {
  final double value = index < values.length ? values[index] : 0;
  final Color color = colorBuilder(value);
  final Color? bg = backgroundBuilder?.call(value);

  return Container(
    width: width,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: bg,
      border: Border.all(color: _gridBorder.withOpacity(.5), width: 0.6),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      formatter(value),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );
}

Color _productivityColor(double value) {
  if (!value.isFinite || value <= 0) return _textSecondary;
  if (value < 80) return const Color(0xFFFF6B6B);
  if (value < 95) return const Color(0xFFFFC56F);
  return const Color(0xFF38D893);
}

Color? _productivityBackground(double value) {
  if (!value.isFinite || value <= 0) return null;
  if (value < 80) return const Color(0x33FF6B6B);
  if (value < 95) return const Color(0x33FFC56F);
  return const Color(0x3338D893);
}
