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
  static const double kRowHeight = 68;
  static const double kHeaderHeight = 72;
  static const double kRowGap = 10;
  static const double kModelWidth = 200;
  static const double kChipWidth = 72;
  static const double kChipGap = 8;
  static const double kStationWidth = 220;
  static const double kHourWidth = 170;
  static const double kHourGap = 12;
  static const double kColumnGap = 18;
  static const double kRailHorizontalPadding = 24;

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

  @override
  Widget build(BuildContext context) {
    final rows = widget.view.rows;
    final hours = widget.view.hours;
    final borderColor = Colors.white.withOpacity(.08);
    final hourColumnsWidth = hours.isEmpty
        ? kHourWidth
        : hours.length * kHourWidth + (hours.length - 1) * kHourGap;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        const railContentWidth =
            (kModelWidth + 4 + 1 + 6 + kStationWidth + 4 + 1 + 6 + (kChipWidth * 3) + (kChipGap * 2));
        const desiredLeftWidth = railContentWidth + kRailHorizontalPadding;
        final available = (maxWidth - kColumnGap).clamp(0.0, double.infinity);
        final needsRailScroll = available < desiredLeftWidth;
        final leftWidth = needsRailScroll
            ? available.clamp(kRailHorizontalPadding, desiredLeftWidth)
            : desiredLeftWidth;

        return Column(
          children: [
            _buildHeader(
              leftWidth,
              borderColor,
              hourColumnsWidth,
              hours,
              needsRailScroll,
              railContentWidth,
            ),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: leftWidth,
                    child: ListView.builder(
                      controller: _vLeftCtrl,
                      padding: EdgeInsets.zero,
                      physics: const ClampingScrollPhysics(),
                      itemExtent: kRowHeight + kRowGap,
                      itemCount: rows.length,
                      itemBuilder: (_, index) {
                        final row = rows[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: kRowGap),
                          child: _LeftRow(
                            row: row,
                            borderColor: borderColor,
                            allowHorizontalScroll: needsRailScroll,
                            railContentWidth: railContentWidth,
                            onTapStation: widget.onStationTap == null
                                ? null
                                : () => widget.onStationTap!(row),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: kColumnGap),
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
                            return Padding(
                              padding: const EdgeInsets.only(bottom: kRowGap),
                              child: Row(
                                children: List.generate(hours.length, (col) {
                                  final metric = row.metrics.length > col
                                      ? row.metrics[col]
                                      : const OtCellMetrics(pass: 0, yr: 0, rr: 0);
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: col == hours.length - 1 ? 0 : kHourGap,
                                    ),
                                    child: Container(
                                      width: kHourWidth,
                                      height: kRowHeight,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0x0FFFFFFF),
                                        border: Border.all(color: borderColor),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: TripleCell(
                                        pass: metric.pass,
                                        yr: metric.yr,
                                        rr: metric.rr,
                                        compact: false,
                                        onTapYr: widget.onSectionTap != null &&
                                                metric.yr > 0
                                            ? () => widget.onSectionTap!(
                                                  row,
                                                  hours[col],
                                                )
                                            : null,
                                        onTapRr: widget.onSectionTap != null &&
                                                metric.pass > 0 &&
                                                metric.rr > 0
                                            ? () => widget.onSectionTap!(
                                                  row,
                                                  hours[col],
                                                )
                                            : null,
                                      ),
                                    ),
                                  );
                                }),
                              ),
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
  ) {
    return Row(
      children: [
        Container(
          width: leftWidth,
          height: kHeaderHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF143A64),
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildRailHeaderContent(borderColor, allowRailScroll, railContentWidth),
        ),
        SizedBox(width: kColumnGap),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF143A64),
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'PASS   YR   RR',
                            style: TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
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
  ) {
    Widget row = SizedBox(
      width: railContentWidth,
      child: Row(
        children: [
          _headerCell('MODEL NAME', width: kModelWidth, align: TextAlign.left),
          const SizedBox(width: 4),
          _divider(borderColor),
          const SizedBox(width: 6),
          SizedBox(
            width: kStationWidth,
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'STATION',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .3,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _divider(borderColor),
          const SizedBox(width: 6),
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
        child: row,
      ),
    );
  }

  Widget _divider(Color borderColor) =>
      Container(width: 1, height: double.infinity, color: borderColor.withOpacity(.6));

  Widget _headerCell(String text, {required double width, TextAlign align = TextAlign.center}) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: .4,
            color: Colors.white,
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
    required this.allowHorizontalScroll,
    required this.railContentWidth,
    this.onTapStation,
  });

  final OtRowView row;
  final Color borderColor;
  final bool allowHorizontalScroll;
  final double railContentWidth;
  final VoidCallback? onTapStation;

  @override
  Widget build(BuildContext context) {
    Widget content = SizedBox(
      width: railContentWidth,
      child: Row(
        children: [
          SizedBox(
            width: _OtTableState.kModelWidth,
            child: Tooltip(
              message: row.model,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  row.model,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .25,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(width: 1, height: double.infinity, color: borderColor.withOpacity(.6)),
          const SizedBox(width: 6),
          SizedBox(
            width: _OtTableState.kStationWidth,
            child: ClipRect(
              child: MouseRegion(
                cursor: onTapStation != null
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTapStation,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        row.station,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(width: 1, height: double.infinity, color: borderColor.withOpacity(.6)),
          const SizedBox(width: 6),
          _summaryChip(
            '${row.wip}',
            color: Colors.blue,
          ),
          SizedBox(width: _OtTableState.kChipGap),
          _summaryChip(
            '${row.totalPass}',
            color: Colors.green,
            onTap: onTapStation,
          ),
          SizedBox(width: _OtTableState.kChipGap),
          _summaryChip(
            '${row.totalFail}',
            color: Colors.red,
            onTap: onTapStation,
          ),
        ],
      ),
    );

    content = ClipRect(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: allowHorizontalScroll
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        child: content,
      ),
    );

    return Container(
      height: _OtTableState.kRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );
  }

  Widget _summaryChip(String text, {required Color color, VoidCallback? onTap}) {
    Widget chip = Container(
      width: _OtTableState.kChipWidth,
      height: _OtTableState.kRowHeight - 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.45)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: .25,
          ),
        ),
      ),
    );

    if (onTap == null) {
      return chip;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: chip,
      ),
    );
  }
}
