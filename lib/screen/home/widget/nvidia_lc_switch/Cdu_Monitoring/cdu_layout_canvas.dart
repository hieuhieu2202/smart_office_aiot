import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'cdu_node.dart';

class CduLayoutCanvas extends StatefulWidget {
  final String? bgImage;
  final List<CduNode> nodes;

  /// Không cần truyền onNodeTap nữa – canvas tự hiển thị tooltip Overlay.
  final void Function(CduNode node)? onNodeTap;

  const CduLayoutCanvas({
    super.key,
    required this.nodes,
    this.bgImage,
    this.onNodeTap,
  });

  @override
  State<CduLayoutCanvas> createState() => _CduLayoutCanvasState();
}

class _CduLayoutCanvasState extends State<CduLayoutCanvas> {
  final GlobalKey _canvasKey = GlobalKey();

  OverlayEntry? _tooltipEntry;
  CduNode? _tooltipNode;

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  // ================== STATUS LOGIC (dùng chung) ==================
  static const _green = Color(0xFF2ECC71); // RUNNING
  static const _orange = Color(0xFFFF7F27); // STOP (warning)
  static const _black = Color(0xFF111111); // NO CONNECT (OFF)
  static const _gray = Color(0xFF4A4A4A); // NO DATA

  bool _isNoData(Map<String, dynamic> d) {
    if (d.isEmpty) return true;
    final s = (d['Status'] ?? '').toString().toUpperCase();
    final noMonitorKeys =
        d['tool_status'] == null &&
        d['run_status'] == null &&
        d['DateTime'] == null;
    return s == 'NO DATA' || noMonitorKeys;
  }

  ({Color color, String label}) _statusVisual(Map<String, dynamic> d) {
    if (_isNoData(d)) return (color: _gray, label: 'NO DATA');

    final tool = (d['tool_status'] ?? '').toString().toUpperCase();
    final run = (d['run_status'] ?? '').toString().toUpperCase();
    final warn =
        (d['liquid_storage'] == true) ||
        (d['warning']?.toString().toLowerCase() == 'true');

    // Ưu tiên tool_status
    if (tool == 'ON') {
      return warn
          ? (color: _orange, label: 'STOP')
          : (color: _green, label: 'RUNNING');
    }
    if (tool == 'OFF') return (color: _black, label: 'NO CONNECT');

    // Fallback theo run_status
    if (run.contains('WARN')) return (color: _orange, label: 'STOP');
    if (run == 'ON' || run == 'RUNNING')
      return (color: _green, label: 'RUNNING');

    return (color: _gray, label: 'NO DATA');
  }

  // ================== TOOLTIP OVERLAY ==================
  void _removeTooltip() {
    _tooltipEntry?.remove();
    _tooltipEntry = null;
    _tooltipNode = null;
  }

  void _showTooltip(CduNode node) {
    _removeTooltip();
    final ctx = _canvasKey.currentContext;
    if (ctx == null) return;

    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;

    final canvasSize = box.size;
    final canvasTopLeft = box.localToGlobal(Offset.zero);

    // Anchor theo % vị trí node -> toạ độ global
    final anchor =
        canvasTopLeft +
        Offset(node.x * canvasSize.width, node.y * canvasSize.height);

    const tipW = 300.0;
    const gap = 14.0; // khoảng cách badge -> tooltip

    final screen = MediaQuery.of(context).size;

    // tính vị trí không tràn màn hình
    final showLeft = (anchor.dx + gap + tipW > screen.width);
    double left = showLeft ? (anchor.dx - tipW - gap) : (anchor.dx + gap);
    double top = (anchor.dy - 140); // ước lượng neo giữa

    left = left.clamp(8.0, screen.width - tipW - 8.0);
    top = top.clamp(8.0, screen.height - 88.0); // chừa đáy 1 ít

    _tooltipNode = node;
    _tooltipEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Barrier để đóng khi chạm ra ngoài
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeTooltip,
                child: const SizedBox.shrink(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: tipW, // ❗ không cố định height – để tooltip tự co + cuộn
              child: Material(
                type: MaterialType.transparency,
                child: _CduTooltip(
                  node: node,
                  statusResolver: _statusVisual,
                  isNoData: _isNoData,
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_tooltipEntry!);
  }

  // ================== CANVAS ==================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _removeTooltip(),
      child: LayoutBuilder(
        builder: (ctx, b) {
          final w = b.maxWidth;
          final h = b.maxHeight;

          final occupied = <Rect>[];
          final children = <Widget>[];

          // BG
          if (widget.bgImage != null) {
            children.add(
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _BgImage(src: widget.bgImage!),
                ),
              ),
            );
          }

          // Nodes + badge
          for (final n in widget.nodes) {
            final badgeSize = _estimateBadgeSize(n.id, context);
            double left = (n.x * w);
            double top = (n.y * h);

            left = left.clamp(8.0, math.max(8.0, w - badgeSize.width - 8.0));
            top = top.clamp(8.0, math.max(8.0, h - badgeSize.height - 8.0));

            // tránh chồng chéo
            Rect r = Rect.fromLTWH(
              left,
              top,
              badgeSize.width,
              badgeSize.height,
            );
            int safety = 0;
            while (occupied.any((o) => o.overlaps(r)) && safety < 200) {
              top += 6;
              top = top.clamp(8.0, math.max(8.0, h - badgeSize.height - 8.0));
              r = Rect.fromLTWH(left, top, badgeSize.width, badgeSize.height);
              safety++;
              if (safety % 20 == 0) {
                left = (left + 8).clamp(
                  8.0,
                  math.max(8.0, w - badgeSize.width - 8.0),
                );
                r = Rect.fromLTWH(left, top, badgeSize.width, badgeSize.height);
              }
            }
            occupied.add(r);

            children.add(
              Positioned(
                left: r.left,
                top: r.top,
                child: _CduBadge(
                  node: n,
                  statusResolver: _statusVisual,
                  isNoData: _isNoData,
                  isDark: isDark,
                  onTap: () {
                    widget.onNodeTap?.call(n); // tuỳ, thường không cần
                    _showTooltip(n);
                  },
                  onLongPress: () => _showTooltip(n),
                ),
              ),
            );
          }

          return Stack(
            key: _canvasKey,
            clipBehavior: Clip.none,
            children: children,
          );
        },
      ),
    );
  }

  Size _estimateBadgeSize(String text, BuildContext context) {
    final base =
        Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w700);

    final tp = TextPainter(
      text: TextSpan(text: text, style: base),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    double w = tp.width + 16;
    double h = tp.height + 6;
    w = w.clamp(44.0, 220.0);
    h = h.clamp(22.0, 40.0);
    return Size(w, h);
  }
}

// ================== BG IMAGE ==================
class _BgImage extends StatelessWidget {
  final String src;

  const _BgImage({required this.src});

  @override
  Widget build(BuildContext context) {
    final s = src.trim();
    if (s.startsWith('data:image')) {
      try {
        final base64Part = s.split(',').last;
        final bytes = base64Decode(base64Part);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {}
    }
    if (s.startsWith('http')) return Image.network(s, fit: BoxFit.cover);
    return Image.asset(s, fit: BoxFit.cover);
  }
}

// ================== BADGE ==================
class _CduBadge extends StatelessWidget {
  final CduNode node;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isDark;

  final ({Color color, String label}) Function(Map<String, dynamic>)
  statusResolver;
  final bool Function(Map<String, dynamic>) isNoData;

  const _CduBadge({
    required this.node,
    required this.onTap,
    required this.onLongPress,
    required this.isDark,
    required this.statusResolver,
    required this.isNoData,
  });

  @override
  Widget build(BuildContext context) {
    final st = statusResolver(node.detail); // màu badge thống nhất với tooltip
    final shadow = Colors.black.withOpacity(0.25);

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: st.color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 6, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 0.7),
      ),
      child: Text(
        node.id,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.05,
          letterSpacing: 0.2,
        ),
      ),
    );

    final useMouse =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    return useMouse
        ? MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(onTap: onTap, onLongPress: onLongPress, child: child),
        )
        : GestureDetector(onTap: onTap, onLongPress: onLongPress, child: child);
  }
}

// ================== TOOLTIP (OVERLAY, 2 DÒNG/Ô) ==================
class _CduTooltip extends StatelessWidget {
  final CduNode node;
  final ({Color color, String label}) Function(Map<String, dynamic>)
  statusResolver;
  final bool Function(Map<String, dynamic>) isNoData;

  const _CduTooltip({
    required this.node,
    required this.statusResolver,
    required this.isNoData,
  });

  String _formatUpdateTime(Map<String, dynamic> d, {required bool nd}) {
    if (nd) return '-';

    String? x = d['DateTime']?.toString();

    // Fallback nếu API dùng tên khác
    x ??= d['UpdateTime']?.toString();
    x ??= d['date_time']?.toString();
    x ??= d['datetime']?.toString();

    if (x == null || x.isEmpty) return '-';

    final m = RegExp(r'\/Date\((\d+)\)\/').firstMatch(x);
    if (m != null) {
      final ms = int.tryParse(m.group(1)!);
      if (ms != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(ms);
        String two(int n) => n.toString().padLeft(2, '0');
        return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
            '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
      }
    }

    try {
      final dt = DateTime.parse(x);
      String two(int n) => n.toString().padLeft(2, '0');
      return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
          '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
    } catch (_) {
      return x;
    }
  }

  String _numOrDash(dynamic v, {int frac = 1, required bool nd}) {
    if (nd) return '-';
    final n = num.tryParse('$v');
    return n == null ? '-' : n.toStringAsFixed(frac);
  }

  // Ô 2 dòng: nhãn (trên) + giá trị (dưới)
  Widget _tile(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = node.detail;
    final nd = isNoData(d);
    final hostName = (d['HostName'] ?? '').toString();
    final ip = (d['IPAddress'] ?? '').toString();

    final st = statusResolver(d);

    final leftCol = [
      _tile(
        'amb_temp_t4',
        '${_numOrDash(d['amb_temp_t4'], frac: 1, nd: nd)}°C',
        strong: true,
      ),
      _tile(
        'tcs_temp_t1_1',
        '${_numOrDash(d['tcs_supply_temp_t1_1'], frac: 1, nd: nd)}°C',
      ),
      _tile(
        'tcs_flow_f1',
        '${_numOrDash(d['tcs_flow_f1'], frac: 1, nd: nd)} LPM',
        strong: true,
      ),
      _tile(
        'pressure_p2',
        '${_numOrDash(d['tcs_return_pressure_p2'], frac: 1, nd: nd)} kPa',
        strong: true,
      ),
    ];
    final rightCol = [
      _tile(
        'tcs_temp_t2',
        '${_numOrDash(d['tcs_return_temp_t2'], frac: 1, nd: nd)}°C',
      ),
      _tile(
        'tcs_temp_t1_2',
        '${_numOrDash(d['tcs_supply_temp_t1_2'], frac: 1, nd: nd)}°C',
      ),
      _tile(
        'pressure_p1',
        '${_numOrDash(d['tcs_supply_pressure_p1'], frac: 1, nd: nd)} kPa',
        strong: true,
      ),
      _tile(
        'liquid_storage',
        nd ? '-' : ((d['liquid_storage'] == true) ? 'WARNING' : 'NORMAL'),
        strong: !nd && d['liquid_storage'] == true,
      ),
    ];

    final maxH = MediaQuery.of(context).size.height - 16; // tránh overflow tổng

    return Material(
      color: Colors.transparent,
      elevation: 12,
      borderRadius: BorderRadius.circular(14),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 300, maxHeight: maxH),
        child: SingleChildScrollView(
          // cho phép cuộn nếu nội dung cao
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: st.color, // nền = màu CDU
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 0.8,
              ),
            ),
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                height: 1.2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          node.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (hostName.isNotEmpty)
                        Text(
                          hostName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                  if (ip.isNotEmpty)
                    Text(
                      ip,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  const SizedBox(height: 6),

                  // Dòng trạng thái theo màu
                  Center(
                    child: Text(
                      st.label, // RUNNING / STOP / NO CONNECT / NO DATA
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: .5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Bảng 2 cột – ô 2 dòng
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              for (int i = 0; i < leftCol.length; i++) ...[
                                leftCol[i],
                                if (i != leftCol.length - 1)
                                  const Divider(
                                    height: 10,
                                    thickness: .6,
                                    color: Colors.white24,
                                  ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 120,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          color: Colors.white24,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              for (int i = 0; i < rightCol.length; i++) ...[
                                rightCol[i],
                                if (i != rightCol.length - 1)
                                  const Divider(
                                    height: 10,
                                    thickness: .6,
                                    color: Colors.white24,
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'UpdateTime: ${_formatUpdateTime(d, nd: nd)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
