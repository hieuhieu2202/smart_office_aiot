import 'package:flutter/material.dart';

import 'cells.dart';
import 'output_tracking_view_state.dart';
import 'series_utils.dart';

class OtTable extends StatefulWidget {
  const OtTable({
    super.key,
    required this.view,
  });

  final OtViewState view;

  @override
  State<OtTable> createState() => _OtTableState();
}

class _OtTableState extends State<OtTable> {
  static const double kRowHeight = 44;
  static const double kHeaderHeight = 46;
  static const double kRowGap = 4;
  static const double kModelWidth = 148;
  static const double kChipWidth = 38;
  static const double kChipGap = 4;
  static const double kHourWidth = 136;
  static const double kHourGap = 4;
  static const double kColumnGap = 8;

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
        final minLeftWidth = (kModelWidth + 4 + (kChipWidth * 3) + (kChipGap * 2) + 8)
            .clamp(0.0, maxWidth);
        final leftWidth = _clamp(
          maxWidth * 0.70,
          min: minLeftWidth,
          max: maxWidth - kColumnGap,
        );

        return Column(
          children: [
            _buildHeader(leftWidth, borderColor, hourColumnsWidth, hours),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0x0FFFFFFF),
                                        border: Border.all(color: borderColor),
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: TripleCell(
                                        pass: metric.pass,
                                        yr: metric.yr,
                                        rr: metric.rr,
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
  ) {
    return Row(
      children: [
        Container(
          width: leftWidth,
          height: kHeaderHeight,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF143A64),
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _headerCell('MODEL NAME', width: kModelWidth, align: TextAlign.left),
              const SizedBox(width: 4),
              _divider(borderColor),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'STATION',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .3,
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
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF143A64),
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            'PASS   YR   RR',
                            style: TextStyle(fontSize: 9, color: Colors.white70),
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
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: .3,
          ),
        ),
      ),
    );
  }

  double _clamp(double value, {required double min, required double max}) {
    final lower = min <= max ? min : max;
    final upper = min <= max ? max : min;
    if (value < lower) return lower;
    if (value > upper) return upper;
    return value;
  }
}

class _LeftRow extends StatelessWidget {
  const _LeftRow({
    required this.row,
    required this.borderColor,
  });

  final OtRowView row;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _OtTableState.kRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(9),
      ),
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
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(width: 1, height: double.infinity, color: borderColor.withOpacity(.6)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRect(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    row.station,
                    softWrap: false,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(width: 1, height: double.infinity, color: borderColor.withOpacity(.6)),
          const SizedBox(width: 6),
          _summaryChip('${row.wip}', color: Colors.blue),
          SizedBox(width: _OtTableState.kChipGap),
          _summaryChip('${row.totalPass}', color: Colors.green),
          SizedBox(width: _OtTableState.kChipGap),
          _summaryChip('${row.totalFail}', color: Colors.red),
        ],
      ),
    );
  }

  Widget _summaryChip(String text, {required Color color}) {
    return Container(
      width: _OtTableState.kChipWidth,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(.45)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
