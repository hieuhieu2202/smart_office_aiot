import 'package:flutter/material.dart';
import 'cells.dart';

class OtTable extends StatefulWidget {
  final List<String> hours;
  final List<String> groups; // STATION
  final Map<String, String> modelNameByGroup; // group -> model name
  final Map<String, List<double>> passByGroup;
  final Map<String, List<double>> yrByGroup;
  final Map<String, List<double>> rrByGroup;
  final Map<String, int> wipByGroup;
  final Map<String, int> totalPassByGroup;
  final Map<String, int> totalFailByGroup;

  const OtTable({
    super.key,
    required this.hours,
    required this.groups,
    required this.modelNameByGroup,
    required this.passByGroup,
    required this.yrByGroup,
    required this.rrByGroup,
    required this.wipByGroup,
    required this.totalPassByGroup,
    required this.totalFailByGroup,
  });

  @override
  State<OtTable> createState() => _OtTableState();
}

class _OtTableState extends State<OtTable> {
  // ==== KÍCH THƯỚC COMPACT (có thể tinh chỉnh nhanh) ====
  static const double kRowH    = 34.0;  // cao 1 hàng dữ liệu
  static const double kVGap    = 2.0;   // khoảng cách dọc giữa hàng
  static const double kHdrH    = 33.0;  // cao header
  static const double kChipW   = 30.0;  // rộng WIP/PASS/FAIL
  static const double kChipGap = 4.0;   // khoảng giữa 3 chip
  static const double kModelW  = 96.0;  // rộng cột MODEL NAME
  static const double kHourW   = 128.0; // rộng 1 cột giờ
  static const double kColGap  = 6.0;   // gap giữa khối trái & phải
  static const double kHourGap = 1.0;   // gap giữa các cột giờ

  // --- Scroll ngang: header & body đồng bộ qua 2 controller ---
  final ScrollController _hHeaderCtrl = ScrollController();
  final ScrollController _hBodyCtrl   = ScrollController();
  bool _isSyncingH = false;

  // --- Scroll dọc: trái & phải đồng bộ ---
  final _vLeft = ScrollController();
  final _vGrid = ScrollController();

  @override
  void initState() {
    super.initState();

    // Đồng bộ NGANG (header <-> body)
    _hHeaderCtrl.addListener(() {
      if (_isSyncingH) return;
      _isSyncingH = true;
      if (_hBodyCtrl.hasClients) {
        final t = _hHeaderCtrl.offset;
        _hBodyCtrl.jumpTo(
          t.clamp(_hBodyCtrl.position.minScrollExtent, _hBodyCtrl.position.maxScrollExtent),
        );
      }
      _isSyncingH = false;
    });

    _hBodyCtrl.addListener(() {
      if (_isSyncingH) return;
      _isSyncingH = true;
      if (_hHeaderCtrl.hasClients) {
        final t = _hBodyCtrl.offset;
        _hHeaderCtrl.jumpTo(
          t.clamp(_hHeaderCtrl.position.minScrollExtent, _hHeaderCtrl.position.maxScrollExtent),
        );
      }
      _isSyncingH = false;
    });

    // Đồng bộ DỌC (trái <-> phải)
    _vGrid.addListener(() {
      if (_vLeft.hasClients && _vLeft.offset != _vGrid.offset) {
        _vLeft.jumpTo(_vGrid.offset);
      }
    });
    _vLeft.addListener(() {
      if (_vGrid.hasClients && _vGrid.offset != _vLeft.offset) {
        _vGrid.jumpTo(_vLeft.offset);
      }
    });
  }

  @override
  void dispose() {
    _hHeaderCtrl.dispose();
    _hBodyCtrl.dispose();
    _vLeft.dispose();
    _vGrid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = Colors.white.withOpacity(.08);
    final hours  = widget.hours;
    final cols   = hours.length;

    final double gridW =
    (cols == 0) ? kHourW : (cols * kHourW + (cols - 1) * kHourGap);

    return LayoutBuilder(builder: (context, cons) {
      final maxW = cons.maxWidth;

      // Bên trái chiếm ~70% nhưng không nhỏ hơn phần tối thiểu
      final double minLeft = (kModelW + 4 + (kChipW * 3) + (kChipGap * 2) + 8)
          .clamp(0.0, maxW);
      final double leftW = _clampSafe(maxW * 0.70, min: minLeft, max: maxW - kColGap);

      return Column(
        children: [
          // ================== HEADER ==================
          Row(
            children: [
              Container(
                width: leftW,
                height: kHdrH,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF143A64),
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _hdrCell('MODEL NAME', width: kModelW, align: TextAlign.left),
                    const SizedBox(width: 4),

                    // Ngăn MODEL NAME ↔ STATION
                    _vDivider(color: Colors.white.withOpacity(.12)),
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

                    // Ngăn STATION ↔ chips
                    const SizedBox(width: 4),
                    _vDivider(color: Colors.white.withOpacity(.12)),
                    const SizedBox(width: 6),

                    _hdrCell('WIP',  width: kChipW),
                    SizedBox(width: kChipGap),
                    _hdrCell('PASS', width: kChipW),
                    SizedBox(width: kChipGap),
                    _hdrCell('FAIL', width: kChipW),
                  ],
                ),
              ),
              SizedBox(width: kColGap),

              // Header giờ (cuộn cùng _hBodyCtrl)
              Expanded(
                child: SingleChildScrollView(
                  controller: _hHeaderCtrl,
                  primary: false,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: gridW,
                    child: Row(
                      children: List.generate(cols, (i) {
                        return Padding(
                          padding: EdgeInsets.only(right: i == cols - 1 ? 0 : kHourGap),
                          child: Container(
                            width: kHourW,
                            height: kHdrH,
                            decoration: BoxDecoration(
                              color: const Color(0xFF143A64),
                              border: Border.all(color: border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _formatHourRange(hours[i]),
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
          ),

          // ================== BODY ==================
          Expanded(
            child: Row(
              children: [
                // Trái (MODEL | STATION | WIP | PASS | FAIL)
                SizedBox(
                  width: leftW,
                  child: ListView.builder(
                    controller: _vLeft,
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: widget.groups.length,
                    itemExtent: kRowH + kVGap,
                    itemBuilder: (_, i) {
                      final station = widget.groups[i];
                      final model   = widget.modelNameByGroup[station]?.trim() ?? '-';
                      final wip = widget.wipByGroup[station] ?? 0;
                      final p   = widget.totalPassByGroup[station] ?? 0;
                      final f   = widget.totalFailByGroup[station] ?? 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: kVGap),
                        child: Container(
                          height: kRowH,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: const Color(0x0FFFFFFF),
                            border: Border.all(color: border),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            children: [
                              // MODEL NAME: cuộn ngang
                              SizedBox(
                                width: kModelW,
                                child: ClipRect(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const ClampingScrollPhysics(),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        model.isEmpty ? '-' : model,
                                        softWrap: false,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: .2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),

                              // Ngăn MODEL NAME ↔ STATION
                              _vDivider(color: Colors.white.withOpacity(.08)),
                              const SizedBox(width: 6),

                              // STATION: cuộn ngang
                              Expanded(
                                child: ClipRect(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const ClampingScrollPhysics(),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        station,
                                        softWrap: false,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Ngăn STATION ↔ chips
                              const SizedBox(width: 4),
                              _vDivider(color: Colors.white.withOpacity(.08)),
                              const SizedBox(width: 6),

                              _chip('$wip', color: Colors.blue,  width: kChipW),
                              SizedBox(width: kChipGap),
                              _chip('$p',   color: Colors.green, width: kChipW),
                              SizedBox(width: kChipGap),
                              _chip('$f',   color: Colors.red,   width: kChipW),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: kColGap),

                // Phải (lưới giờ) — đồng bộ ngang với header
                Expanded(
                  child: SingleChildScrollView(
                    controller: _hBodyCtrl,
                    primary: false,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: gridW,
                      child: ListView.builder(
                        controller: _vGrid,
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: widget.groups.length,
                        itemExtent: kRowH + kVGap,
                        itemBuilder: (_, r) {
                          final g = widget.groups[r];
                          final pass = _seriesFor(g, widget.passByGroup, cols);
                          final yr   = _seriesFor(g, widget.yrByGroup,   cols);
                          final rr   = _seriesFor(g, widget.rrByGroup,   cols);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: kVGap),
                            child: Row(
                              children: List.generate(cols, (c) {
                                return Padding(
                                  padding: EdgeInsets.only(right: c == cols - 1 ? 0 : kHourGap),
                                  child: Container(
                                    width: kHourW,
                                    height: kRowH,
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0x0FFFFFFF),
                                      border: Border.all(color: border),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: TripleCell(
                                      pass: (pass[c].isNaN ? 0 : pass[c]),
                                      yr:   (yr[c].isNaN   ? 0 : yr[c]),
                                      rr:   (rr[c].isNaN   ? 0 : rr[c]),
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
    });
  }

  // ---------- Helpers ----------
  static double _clampSafe(double v, {required double min, required double max}) {
    final lo = min <= max ? min : max;
    final hi = min <= max ? max : min;
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
  }

  Widget _vDivider({required Color color}) {
    return Container(width: 1.0, height: double.infinity, color: color);
  }

  Widget _hdrCell(String t, {required double width, TextAlign align = TextAlign.center}) {
    return SizedBox(
      width: width,
      child: Text(
        t,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
      ),
    );
  }

  List<double> _seriesFor(String g, Map<String, List<double>> src, int len) {
    if (len <= 0) return const <double>[];
    final raw = src[g] ?? const <double>[];
    if (raw.length == len) return raw;
    if (raw.length > len)  return List<double>.from(raw.take(len));
    return [...raw, ...List<double>.filled(len - raw.length, 0)];
  }

  Widget _chip(String t, {required Color color, required double width}) {
    return Container(
      width: width,
      height: kRowH - 10,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Text(
        t,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 9),
      ),
    );
  }

  // "08" -> "07:30 - 08:30"; nếu đã có ":" thì giữ nguyên
  String _formatHourRange(String s) {
    final raw = s.trim();
    if (raw.contains(':')) return raw;
    final h = int.tryParse(raw);
    if (h == null) return raw;
    final endH = (h % 24);
    final startH = (h - 1) < 0 ? 23 : (h - 1);
    final start = '${_two(startH)}:30';
    final end   = '${_two(endH)}:30';
    return '$start - $end';
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}
