import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cells.dart';
import 'output_tracking_view_state.dart';
import 'series_utils.dart';

class OtTable extends StatefulWidget {
  const OtTable({
    super.key,
    required this.view,
    this.onStationTap,
    this.onSectionTap,
  });

  final OtViewState view;
  final void Function(OtRowView row)? onStationTap;
  final void Function(OtRowView row, String section)? onSectionTap;

  @override
  State<OtTable> createState() => _OtTableState();
}

class _OtTableState extends State<OtTable> {
  static const double kRowHeight = 50;
  static const double kHeaderHeight = 52;
  static const double kRowGap = 0;
  static const double kModelWidth = 220;
  static const double kChipWidth = 72;
  static const double kChipGap = 0;
  static const double kStationMinWidth = 132;
  static const double kStationPadding = 16;
  static const double kStationMaxWidth = 220;
  static const double kHourWidth = 146;
  static const double kHourGap = 0;
  static const double kColumnGap = 0;
  static const double kDividerGapBefore = 2;
  static const double kDividerGapAfter = 2;
  static const double kDividerWidth = 1;
  static const double kHeaderPaddingY = 0;
  static const BorderRadius kCellRadius = BorderRadius.zero;

  static const Color kHeaderBackground = Color(0xFF17375E);
  static const Color kHeaderBorder = Color(0xFF2A4B7A);
  static const Color kRailBackground = Color(0xFF0E1F36);
  static const Color kHourBackground = Color(0xFF10253F);
  static const Color kGridBorder = Color(0xFF1C2F4A);

  static double get kDividerTotal =>
      kDividerGapBefore + kDividerWidth + kDividerGapAfter;
  double _summaryWidthFor(double stationWidth) =>
      stationWidth + kDividerTotal + (kChipWidth * 3) + (kChipGap * 2);

  double _stationWidthForRows(List<OtRowView> rows) {
    final stations = rows.isEmpty
        ? const <String>['STATION']
        : rows.map((r) => r.station).where((name) => name.trim().isNotEmpty);

    double widest = 0;
    const style = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: .2,
    );

    for (final station in stations) {
      final painter = TextPainter(
        text: TextSpan(text: station, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      widest = math.max(widest, painter.width);
    }

    final desired = widest + kStationPadding;
    return desired.clamp(kStationMinWidth, kStationMaxWidth);
  }

  final ScrollController _hHeaderCtrl = ScrollController();
  final ScrollController _hBodyCtrl = ScrollController();
  final ScrollController _vLeftCtrl = ScrollController();
  final ScrollController _vRightCtrl = ScrollController();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();

    _hHeaderCtrl.addListener(() => _syncHorizontal(_hHeaderCtrl, _hBodyCtrl));
    _hBodyCtrl.addListener(() => _syncHorizontal(_hBodyCtrl, _hHeaderCtrl));

    _vLeftCtrl.addListener(() => _syncVertical(_vLeftCtrl, _vRightCtrl));
    _vRightCtrl.addListener(() => _syncVertical(_vRightCtrl, _vLeftCtrl));
  }

  @override
  void dispose() {
    _hHeaderCtrl.dispose();
    _hBodyCtrl.dispose();
    _vLeftCtrl.dispose();
    _vRightCtrl.dispose();
    super.dispose();
  }

  void _syncHorizontal(ScrollController source, ScrollController target) {
    if (_isSyncing) return;
    if (!source.hasClients || !target.hasClients) return;
    _isSyncing = true;
    target.jumpTo(source.offset.clamp(
      target.position.minScrollExtent,
      target.position.maxScrollExtent,
    ));
    _isSyncing = false;
  }

  void _syncVertical(ScrollController source, ScrollController target) {
    if (!source.hasClients || !target.hasClients) return;
    if ((source.offset - target.offset).abs() < 0.5) return;
    target.jumpTo(source.offset.clamp(
      target.position.minScrollExtent,
      target.position.maxScrollExtent,
    ));
  }

  double _modelWidthForText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return kModelWidth;

    const style = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: .2,
    );

    final lines = trimmed.split('\n');
    double widest = 0;
    for (final line in lines) {
      final painter = TextPainter(
        text: TextSpan(text: line, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      widest = math.max(widest, painter.width);
    }

    return math.max(kModelWidth, widest + 28);
  }

  double _rowsHeight(int count) {
    if (count <= 0) return kRowHeight;
    if (count == 1) return kRowHeight;
    return (kRowHeight * count) + (kRowGap * (count - 1));
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.view.rows;
    final hours = widget.view.hours;
    const borderColor = kGridBorder;
    final hourColumnsWidth = hours.isEmpty
        ? kHourWidth
        : hours.length * kHourWidth + (hours.length - 1) * kHourGap;
    final modelWidth = _modelWidthForText(widget.view.modelsText);
    final stationWidth = _stationWidthForRows(rows);
    final summaryWidth = _summaryWidthFor(stationWidth);
    final railContentWidth = modelWidth + kDividerTotal + summaryWidth;
    final railShellWidth = railContentWidth;
    final totalRailHeight = _rowsHeight(rows.length);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final available = (maxWidth - kColumnGap).clamp(0.0, double.infinity);
        final safeWidth = available.isFinite && available > 0 ? available : railShellWidth;
        final needsRailScroll = safeWidth + 0.5 < railShellWidth;
        final desiredWidth = needsRailScroll ? safeWidth : railShellWidth;
        final leftWidth = desiredWidth.clamp(0.0, maxWidth);

        return Column(
          children: [
            _buildHeader(
              leftWidth,
              borderColor,
              hourColumnsWidth,
              hours,
              needsRailScroll,
              railContentWidth,
              modelWidth,
              stationWidth,
            ),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: leftWidth,
                    child: _LeftRail(
                      rows: rows,
                      modelsText: widget.view.modelsText,
                      modelWidth: modelWidth,
                      railContentWidth: railContentWidth,
                      summaryWidth: summaryWidth,
                      stationWidth: stationWidth,
                      totalHeight: totalRailHeight,
                      controller: _vLeftCtrl,
                      allowHorizontalScroll: needsRailScroll,
                      borderColor: borderColor,
                      onStationTap: widget.onStationTap,
                    ),
                  ),
                  if (kColumnGap > 0) SizedBox(width: kColumnGap),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _hBodyCtrl,
                      scrollDirection: Axis.horizontal,
                      primary: false,
                      child: SizedBox(
                        width: hourColumnsWidth,
                        child: ListView.builder(
                          controller: _vRightCtrl,
                          padding: EdgeInsets.zero,
                          physics: const ClampingScrollPhysics(),
                          itemExtent: kRowHeight + kRowGap,
                          itemCount: rows.length,
                          itemBuilder: (_, rowIndex) {
                            final row = rows[rowIndex];
                            return Row(
                              children: List.generate(hours.length, (col) {
                                  final metric = row.metrics.length > col
                                      ? row.metrics[col]
                                      : const OtCellMetrics(pass: 0, yr: 0, rr: 0);
                                  return Container(
                                    width: kHourWidth,
                                    height: kRowHeight,
                                    decoration: BoxDecoration(
                                      color: kHourBackground,
                                      border: Border.all(
                                        color: borderColor.withOpacity(.65),
                                        width: .7,
                                      ),
                                      borderRadius: kCellRadius,
                                    ),
                                    child: TripleCell(
                                      pass: metric.pass,
                                      yr: metric.yr,
                                      rr: metric.rr,
                                      compact: true,
                                      onTapYr: widget.onSectionTap != null && metric.yr > 0
                                          ? () => widget.onSectionTap!(
                                                row,
                                                hours[col],
                                              )
                                          : null,
                                      onTapRr: widget.onSectionTap != null && metric.pass > 0 && metric.rr > 0
                                          ? () => widget.onSectionTap!(
                                                row,
                                                hours[col],
                                              )
                                          : null,
                                    ),
                                  );
                                }),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    double leftWidth,
    Color borderColor,
    double hourColumnsWidth,
    List<String> hours,
    bool allowRailScroll,
    double railContentWidth,
    double modelWidth,
    double stationWidth,
  ) {
    return Row(
      children: [
        Container(
          width: leftWidth,
          height: kHeaderHeight,
          padding: const EdgeInsets.symmetric(vertical: kHeaderPaddingY),
          decoration: BoxDecoration(
            color: kHeaderBackground,
            border: Border.all(color: kHeaderBorder.withOpacity(.7), width: .8),
            borderRadius: kCellRadius,
          ),
          child: _buildRailHeaderContent(
            borderColor,
            allowRailScroll,
            railContentWidth,
            modelWidth,
            stationWidth,
          ),
        ),
        if (kColumnGap > 0) SizedBox(width: kColumnGap),
        Expanded(
          child: SingleChildScrollView(
            controller: _hHeaderCtrl,
            scrollDirection: Axis.horizontal,
            primary: false,
            child: SizedBox(
              width: hourColumnsWidth,
              child: Row(
                children: List.generate(hours.length, (index) {
                  final label = formatHourRange(hours[index]);
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == hours.length - 1 ? 0 : kHourGap,
                    ),
                    child: Container(
                      width: kHourWidth,
                      height: kHeaderHeight,
                      decoration: BoxDecoration(
                        color: kHeaderBackground,
                        border: Border.all(
                          color: kHeaderBorder.withOpacity(.7),
                          width: .8,
                        ),
                        borderRadius: kCellRadius,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: .25,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: kHeaderBorder.withOpacity(.65),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 22,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: const [
                                _HourLegendCell(label: 'PASS', showRightBorder: true),
                                _HourLegendCell(label: 'YR', showRightBorder: true),
                                _HourLegendCell(label: 'RR', showRightBorder: false),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRailHeaderContent(
    Color borderColor,
    bool allowRailScroll,
    double railContentWidth,
    double modelWidth,
    double stationWidth,
  ) {
    Widget row = SizedBox(
      width: railContentWidth,
      child: Row(
        children: [
          _headerCell('MODEL NAME', width: modelWidth, align: TextAlign.left),
          const SizedBox(width: kDividerGapBefore),
          _divider(borderColor),
          const SizedBox(width: kDividerGapAfter),
          SizedBox(
            width: stationWidth,
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'STATION',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: kDividerGapBefore),
          _divider(borderColor),
          const SizedBox(width: kDividerGapAfter),
          _headerCell('WIP', width: kChipWidth),
          SizedBox(width: kChipGap),
          _headerCell('PASS', width: kChipWidth),
          SizedBox(width: kChipGap),
          _headerCell('FAIL', width: kChipWidth),
        ],
      ),
    );

    return ClipRect(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: allowRailScroll
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        clipBehavior: Clip.none,
        child: row,
      ),
    );
  }

  Widget _divider(Color borderColor) => Container(
        width: 1,
        height: double.infinity,
        color: borderColor.withOpacity(.7),
      );

  Widget _headerCell(String text, {required double width, TextAlign align = TextAlign.center}) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: align == TextAlign.left ? Alignment.centerLeft : Alignment.center,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: align == TextAlign.left ? 10 : 0),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: .25,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

}

class _LeftRail extends StatelessWidget {
  const _LeftRail({
    required this.rows,
    required this.modelsText,
    required this.modelWidth,
    required this.railContentWidth,
    required this.summaryWidth,
    required this.stationWidth,
    required this.totalHeight,
    required this.controller,
    required this.allowHorizontalScroll,
    required this.borderColor,
    required this.onStationTap,
  });

  final List<OtRowView> rows;
  final String modelsText;
  final double modelWidth;
  final double railContentWidth;
  final double summaryWidth;
  final double stationWidth;
  final double totalHeight;
  final ScrollController controller;
  final bool allowHorizontalScroll;
  final Color borderColor;
  final void Function(OtRowView row)? onStationTap;

  @override
  Widget build(BuildContext context) {
    final safeHeight = totalHeight <= 0 ? _OtTableState.kRowHeight : totalHeight;
    final displaySummaryWidth = summaryWidth;

    final summaryChildren = <Widget>[];
      if (rows.isEmpty) {
        summaryChildren.add(
          SizedBox(
            height: _OtTableState.kRowHeight,
            width: displaySummaryWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _OtTableState.kRailBackground,
                border: Border.all(color: borderColor.withOpacity(.65), width: .7),
              ),
            ),
          ),
        );
    } else {
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        summaryChildren.add(
          Padding(
            padding: EdgeInsets.only(
              bottom: i == rows.length - 1 ? 0 : _OtTableState.kRowGap,
            ),
            child: _LeftRow(
              row: row,
              borderColor: borderColor,
              width: displaySummaryWidth,
              stationWidth: stationWidth,
              onTapStation:
                  onStationTap == null ? null : () => onStationTap!(row),
            ),
          ),
        );
      }
    }

    final railRow = SizedBox(
      width: railContentWidth,
      height: safeHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MergedModelCell(
            text: modelsText,
            width: modelWidth,
            height: safeHeight,
            borderColor: borderColor,
          ),
          if (displaySummaryWidth > 0) ...[
            const SizedBox(width: _OtTableState.kDividerGapBefore),
            _RailDivider(color: borderColor),
            const SizedBox(width: _OtTableState.kDividerGapAfter),
            SizedBox(
              width: displaySummaryWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: summaryChildren,
              ),
            ),
          ],
        ],
      ),
    );

    final vertical = SingleChildScrollView(
      controller: controller,
      physics: const ClampingScrollPhysics(),
      child: railRow,
    );

    final horizontal = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: allowHorizontalScroll
          ? const ClampingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      child: SizedBox(
        width: railContentWidth,
        child: vertical,
      ),
    );

    return ClipRect(child: horizontal);
  }
}

class _RailDivider extends StatelessWidget {
  const _RailDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _OtTableState.kDividerWidth,
      height: double.infinity,
      color: color.withOpacity(.7),
    );
  }
}

class _HourLegendCell extends StatelessWidget {
  const _HourLegendCell({
    required this.label,
    required this.showRightBorder,
  });

  final String label;
  final bool showRightBorder;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            right: showRightBorder
                ? BorderSide(
                    color: _OtTableState.kHeaderBorder.withOpacity(.65),
                    width: .6,
                  )
                : BorderSide.none,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _MergedModelCell extends StatelessWidget {
  const _MergedModelCell({
    required this.text,
    required this.width,
    required this.height,
    required this.borderColor,
  });

  final String text;
  final double width;
  final double height;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final display = text.trim().isEmpty ? '-' : text.trim();

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _OtTableState.kRailBackground,
          border: Border.all(color: borderColor.withOpacity(.65), width: .7),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Tooltip(
            message: display,
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                display,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeftRow extends StatelessWidget {
  const _LeftRow({
    required this.row,
    required this.borderColor,
    required this.width,
    required this.stationWidth,
    this.onTapStation,
  });

  final OtRowView row;
  final Color borderColor;
  final double width;
  final double stationWidth;
  final VoidCallback? onTapStation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _OtTableState.kRowHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _OtTableState.kRailBackground,
          border: Border.all(color: borderColor.withOpacity(.65), width: .7),
        ),
        child: Row(
          children: [
            SizedBox(
              width: stationWidth,
              child: MouseRegion(
                cursor: onTapStation != null
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTapStation,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        row.station,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: .2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: _OtTableState.kDividerGapBefore),
            _RailDivider(color: borderColor),
            const SizedBox(width: _OtTableState.kDividerGapAfter),
            _summaryCell(
              '${row.wip}',
              color: const Color(0xFF42A0FF),
            ),
            SizedBox(width: _OtTableState.kChipGap),
            _summaryCell(
              '${row.totalPass}',
              color: const Color(0xFF38D893),
              onTap: onTapStation,
            ),
            SizedBox(width: _OtTableState.kChipGap),
            _summaryCell(
              '${row.totalFail}',
              color: const Color(0xFFFF6B6B),
              onTap: onTapStation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCell(String text, {required Color color, VoidCallback? onTap}) {
    Widget cell = SizedBox(
      width: _OtTableState.kChipWidth,
      height: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _OtTableState.kRailBackground,
          border: Border.all(color: borderColor.withOpacity(.65), width: .7),
        ),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: .15,
            ),
          ),
        ),
      ),
    );

    if (onTap == null) {
      return cell;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: cell,
      ),
    );
  }
}
