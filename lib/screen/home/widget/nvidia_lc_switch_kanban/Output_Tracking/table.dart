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
  static const double kRowHeight = 82;
  static const double kHeaderHeight = 88;
  static const double kRowGap = 8;
  static const double kModelWidth = 236;
  static const double kChipWidth = 92;
  static const double kChipGap = 10;
  static const double kStationWidth = 224;
  static const double kHourWidth = 156;
  static const double kHourGap = 10;
  static const double kColumnGap = 16;
  static const double kRailPaddingX = 18;
  static const double kHeaderPaddingY = 18;
  static const double kRowPaddingY = 16;
  static const BorderRadius kCellRadius = BorderRadius.all(Radius.circular(16));

  static const Color kHeaderBackground = Color(0xFF143A64);
  static const Color kHeaderBorder = Color(0xFF2C5C8F);
  static const Color kRailBackground = Color(0xFF0F223F);
  static const Color kHourBackground = Color(0xFF112B4B);
  static const Color kGridBorder = Color(0xFF1E3F66);

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
    const borderColor = kGridBorder;
    final hourColumnsWidth = hours.isEmpty
        ? kHourWidth
        : hours.length * kHourWidth + (hours.length - 1) * kHourGap;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        const railContentWidth = kModelWidth +
            4 +
            1 +
            6 +
            kStationWidth +
            4 +
            1 +
            6 +
            (kChipWidth * 3) +
            (kChipGap * 2);
        const railShellWidth = railContentWidth + (kRailPaddingX * 2);
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kHourBackground,
                                        border: Border.all(color: borderColor),
                                        borderRadius: kCellRadius,
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
          padding: const EdgeInsets.symmetric(
            horizontal: kRailPaddingX,
            vertical: kHeaderPaddingY,
          ),
          decoration: BoxDecoration(
            color: kHeaderBackground,
            border: Border.all(color: kHeaderBorder),
            borderRadius: kCellRadius,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: kHeaderBackground,
                        border: Border.all(color: kHeaderBorder),
                        borderRadius: kCellRadius,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .25,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'PASS   YR   RR',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
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
                  fontSize: 15,
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
        clipBehavior: Clip.none,
        child: row,
      ),
    );
  }

  Widget _divider(Color borderColor) =>
      Container(width: 1, height: double.infinity, color: borderColor.withOpacity(.9));

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
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: .35,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .3,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(width: 1, height: double.infinity, color: borderColor.withOpacity(.75)),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .25,
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
          Container(width: 1, height: double.infinity, color: borderColor.withOpacity(.75)),
          const SizedBox(width: 6),
          _summaryChip(
            '${row.wip}',
            color: const Color(0xFF42A0FF),
          ),
          SizedBox(width: _OtTableState.kChipGap),
          _summaryChip(
            '${row.totalPass}',
            color: const Color(0xFF38D893),
            onTap: onTapStation,
          ),
          SizedBox(width: _OtTableState.kChipGap),
          _summaryChip(
            '${row.totalFail}',
            color: const Color(0xFFFF6B6B),
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
        clipBehavior: Clip.none,
        child: content,
      ),
    );

    return Container(
      height: _OtTableState.kRowHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: _OtTableState.kRailPaddingX,
        vertical: _OtTableState.kRowPaddingY,
      ),
      decoration: BoxDecoration(
        color: _OtTableState.kRailBackground,
        border: Border.all(color: borderColor),
        borderRadius: _OtTableState.kCellRadius,
      ),
      child: content,
    );
  }

  Widget _summaryChip(String text, {required Color color, VoidCallback? onTap}) {
    final chipHeight = _OtTableState.kRowHeight - (_OtTableState.kRowPaddingY * 2);
    Widget chip = Container(
      width: _OtTableState.kChipWidth,
      height: chipHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.55)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
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
