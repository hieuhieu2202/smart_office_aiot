import 'package:flutter/material.dart';
import '../../../../service/lc_switch_rack_api.dart'
    show RackDetail, SlotDetail;
import 'rack_status_utils.dart';

/// ===== Palette (theo web) =====
class _RackColors {
  static const green = Color(0xFF20C25D);
  static const blue = Color(0xFF1E88E5);
  static const amber = Color(0xFFFFB300);
  static const purple = Color(0xFF7E57C2);
  static const red = Color(0xFFE53935);
  static const offline = Color(0xFF6B7780);

  static Color cardBG(bool dark) =>
      dark ? const Color(0xFF0F2231) : Colors.white;

  static Color chipBG(bool dark) =>
      dark ? const Color(0xFF17334A) : const Color(0xFFF1F6FA);

  static Color slotRowBG(bool dark) =>
      dark ? const Color(0xFF142A3C) : const Color(0xFFF7F9FB);

  static Color border(bool dark) =>
      dark ? Colors.white24 : Colors.grey.shade300;

  // offline / idle tone
  static Color offCardBG(bool dark) =>
      dark ? const Color(0xFF1C2430) : const Color(0xFFF1F3F5);

  static Color offRowBG(bool dark) =>
      dark ? const Color(0xFF2A323A) : const Color(0xFFE9ECEF);

  static Color offText(bool dark) => dark ? Colors.white60 : Colors.black45;

  static Color offBorder(bool dark) =>
      dark ? Colors.white10 : Colors.grey.shade300;
}

Color _statusColor(String? status) {
  switch (normalizeRackStatus(status)) {
    case 'PASS':
      return _RackColors.green;
    case 'TESTING':
      return _RackColors.blue;
    case 'WAITING':
      return _RackColors.amber;
    case 'HOLD':
      return _RackColors.purple;
    case 'FAIL':
      return _RackColors.red;
    default:
      return _RackColors.offline;
  }
}

/// =================== LEGEND BAR ===================
class RackStatusLegendBar extends StatelessWidget {
  const RackStatusLegendBar({super.key, this.margin});

  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0F2C4A), Color(0xFF143254)]
              : const [Color(0xFFEAF3FF), Color(0xFFDCE7FB)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: const [
            _LegendItem(color: _RackColors.green,  label: 'PASS'),
            _LegendItem(color: _RackColors.red,    label: 'FAIL'),
            _LegendItem(color: _RackColors.blue,   label: 'TESTING'),
            _LegendItem(color: _RackColors.amber,  label: 'WAITING'),
            _LegendItem(color: _RackColors.offline,label: 'OFFLINE'),
            _LegendItem(color: _RackColors.purple, label: 'HOLD'),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 4,
                  spreadRadius: .5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: .2,
              color: isDark ? Colors.white : const Color(0xFF0F2540),
            ),
          ),
        ],
      ),
    );
  }
}

/// =================== PANEL: LEGEND + LIST RACK ===================
class RackLeftPanel extends StatelessWidget {
  const RackLeftPanel({super.key, required this.racks});

  final List<RackDetail> racks;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final itemH = (screenH * 0.3).clamp(220.0, 320.0);

    // Danh sách child: khoảng cách mở đầu + từng Rack + khoảng cách
    final children = <Widget>[
      const SizedBox(height: 8),
    ];

    for (int i = 0; i < racks.length; i++) {
      children.add(
        SizedBox(
          height: itemH,
          width: double.infinity,
          child: _RackCard(rack: racks[i]),
        ),
      );
      if (i != racks.length - 1) {
        children.add(const SizedBox(height: 12));
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      sliver: SliverList(
        delegate: SliverChildListDelegate(children),
      ),
    );
  }
}

/// =================== RACK CARD ===================
class _RackCard extends StatefulWidget {
  const _RackCard({required this.rack});
  final RackDetail rack;

  @override
  State<_RackCard> createState() => _RackCardState();
}

class _RackCardState extends State<_RackCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _scaleForWidth(double w) {
    if (w <= 320) return 0.95;
    if (w >= 800) return 1.15;
    return 0.95 + (w - 320) * (1.15 - 0.95) / (800 - 320);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rack = widget.rack;
    final slots = rack.slotDetails;

    final isOffline = isRackOffline(rack, slots: slots);
    final isRunning = isRackRunning(rack, slots: slots);

    return LayoutBuilder(
      builder: (ctx, box) {
        final w = box.maxWidth, h = box.maxHeight, s = _scaleForWidth(w);

        // co top khi card thấp để tránh overflow
        double hs;
        if (h < 200) {
          hs = .88;
        } else if (h < 240) {
          hs = .94;
        } else {
          hs = 1.0;
        }

        // tone theo trạng thái
        final cardColor =
        (isOffline || !isRunning)
            ? _RackColors.offCardBG(isDark)
            : _RackColors.cardBG(isDark);
        final border =
        (isOffline || !isRunning)
            ? _RackColors.offBorder(isDark)
            : _RackColors.border(isDark);
        final textMuted =
        (isOffline || !isRunning) ? _RackColors.offText(isDark) : null;

        // dot: chỉ xanh khi đang chạy
        final dotColor =
        (isRunning && !isOffline) ? _RackColors.green : _RackColors.offline;

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Header: RACK n [nickName] + dot
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${rack.rackName.toUpperCase()}  [${rack.nickName}]',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 11 * s * hs,
                        fontWeight: FontWeight.w900,
                        color: textMuted,
                      ),
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2 * s * hs),

              // ===== PCS
              Center(
                child: Text(
                  '${rack.input} PCS',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20 * s * hs,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4,
                    color: textMuted,
                  ),
                ),
              ),
              SizedBox(height: 6 * s * hs),

              // ===== UT (chip phải xám nếu offline/không chạy)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (isOffline || !isRunning)
                          ? _RackColors.offRowBG(isDark)
                          : _RackColors.chipBG(isDark),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (isOffline || !isRunning)
                            ? _RackColors.offBorder(isDark)
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      'UT: ${rack.ut.toStringAsFixed(2)} %',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: textMuted,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              SizedBox(height: 6 * s * hs),

              // ===== Strip: modelName (SAxxxxx) — xám nếu offline/không chạy
              _Strip(
                text: rack.modelName,
                yr: rack.yr,
                active: isRunning && !isOffline,
                offline: isOffline || !isRunning,
                controller: _ctrl,
              ),

              SizedBox(height: 8 * s * hs),

              // ===== Slot list — dim khi offline/không chạy
              Expanded(
                child: _SlotList(
                  slots: slots,
                  scale: s,
                  dimmed: isOffline || !isRunning,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Strip xanh (khi chạy) / xám (offline hoặc không chạy)
class _Strip extends StatelessWidget {
  const _Strip({
    required this.text,
    required this.yr,
    required this.active,
    required this.offline,
    required this.controller,
  });

  final String text;
  final double yr;
  final bool active; // đang chạy
  final bool offline; // xám nếu true
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (offline || !active) {
      return Container(
        height: 30,
        decoration: BoxDecoration(
          color: _RackColors.offRowBG(isDark),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _RackColors.offBorder(isDark)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _RackColors.offText(isDark),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _yrBadge(
              'Y.R | ${yr.toStringAsFixed(0)} %',
              color: _RackColors.offText(isDark),
              bg: Colors.black12,
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        final start = (t * 1.2 - 0.2).clamp(0.0, 1.0);
        final end = (start + 0.25).clamp(0.0, 1.0);
        return Container(
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFF18B351),
                Color(0xFF30E57A),
                Color(0xFF18B351),
              ],
              stops: [start, (start + end) / 2, end],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _yrBadge(
                'Y.R | ${yr.toStringAsFixed(0)} %',
                color: Colors.white,
                bg: Colors.white24,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _yrBadge(String text, {required Color color, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// =================== SLOT LIST ===================
class _SlotList extends StatefulWidget {
  const _SlotList({
    required this.slots,
    required this.scale,
    required this.dimmed,
  });

  final List<SlotDetail> slots;
  final double scale;
  final bool dimmed; // xám khi offline / không chạy

  @override
  State<_SlotList> createState() => _SlotListState();
}

class _SlotListState extends State<_SlotList> {
  late final ScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Scrollbar(
        controller: _ctrl,
        thumbVisibility: true,
        child: ListView.separated(
          controller: _ctrl,
          primary: false,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: widget.slots.length,
          separatorBuilder: (_, __) => SizedBox(height: 6 * widget.scale),
          itemBuilder: (ctx, i) {
            final s = widget.slots[i];

            // === QUY TẮC XÁM CHO SLOT ===
            final bool slotGray =
                widget.dimmed || isSlotOffline(s) || (s.yr <= 0) ||
                    (s.input == 0 && s.totalPass == 0);

            // Tone theo slotGray
            final rowBG =
            slotGray ? _RackColors.offRowBG(isDark) : _RackColors.slotRowBG(isDark);
            final border =
            slotGray ? _RackColors.offBorder(isDark) : _RackColors.border(isDark);
            final textC =
            slotGray ? _RackColors.offText(isDark) : (isDark ? Colors.white70 : Colors.black87);

            // Màu trạng thái (badge/metrics). Khi xám thì dùng offline-grey
            final stColor = slotGray ? _RackColors.offline : _statusColor(s.status);

            // Tone cho cụm metrics & badge
            final metricsBG     = slotGray ? Colors.black12 : stColor.withOpacity(.10);
            final metricsBorder = slotGray ? _RackColors.offBorder(isDark) : stColor;
            final metricsText   = slotGray ? _RackColors.offText(isDark) : stColor;

            final slotBadgeBG     = slotGray ? Colors.black12 : stColor.withOpacity(.16);
            final slotBadgeBorder = slotGray ? _RackColors.offBorder(isDark) : stColor;
            final slotBadgeText   = slotGray ? _RackColors.offText(isDark) : stColor;

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6 * widget.scale,
              ),
              decoration: BoxDecoration(
                color: rowBG,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  // ===== Badge SLOT
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4 * widget.scale,
                    ),
                    decoration: BoxDecoration(
                      color: slotBadgeBG,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: slotBadgeBorder, width: 1),
                    ),
                    child: Text(
                      'SLOT ${s.slotNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: slotBadgeText,
                        fontSize: 11 * widget.scale,
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * widget.scale),

                  // ===== Tên máy
                  Expanded(
                    child: Text(
                      s.slotName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textC,
                        fontWeight: FontWeight.w600,
                        fontSize: 11 * widget.scale,
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * widget.scale),

                  // ===== Metrics (input/pass | Y.R)
                  Flexible(
                    fit: FlexFit.loose,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4 * widget.scale,
                          ),
                          decoration: BoxDecoration(
                            color: metricsBG,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: metricsBorder),
                          ),
                          child: Text(
                            '${s.input}/${s.totalPass} | ${s.yr.toStringAsFixed(0)} %',
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: metricsText,
                              fontSize: 11 * widget.scale,
                              fontFamily: 'RobotoMono',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
