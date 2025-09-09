import 'package:flutter/material.dart';

class RoomCanvas extends StatefulWidget {
  final List<Map<String, dynamic>> sensors;
  final List<Map<String, dynamic>> racks;

  const RoomCanvas({
    super.key,
    required this.sensors,
    required this.racks,
  });

  @override
  State<RoomCanvas> createState() => _RoomCanvasState();
}

class _RoomCanvasState extends State<RoomCanvas> with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgTop = isDark ? const Color(0xFF0E2A3A) : const Color(0xFFD7ECF7);
    final bgBottom = isDark ? const Color(0xFF0B2433) : const Color(0xFFEAF3F9);
    final lineColor = isDark ? Colors.cyanAccent.withOpacity(.15) : const Color(0xFF1A6C87).withOpacity(.15);

    return LayoutBuilder(builder: (context, size) {
      final w = size.maxWidth;
      final sensorXs = [w * .22, w * .32, w * .68, w * .78];

      return Stack(
        children: [
          // Nền gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bgTop, bgBottom],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Lưới
          CustomPaint(size: Size.infinite, painter: _GridPainter(lineColor)),

          // ===== 4 sensor =====
          Positioned.fill(
            top: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hàng trên
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < widget.sensors.length; i += 2)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                        child: AnimatedSensorBadge(
                          value: widget.sensors[i]['Value'],
                          status: (widget.sensors[i]['Status'] ?? '').toString(),
                          isDark: isDark,
                          delay: const Duration(milliseconds: 0),
                        ),
                      ),
                  ],
                ),
                // Hàng dưới (so le)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 30),
                    for (int i = 1; i < widget.sensors.length; i += 2)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                        child: AnimatedSensorBadge(
                          value: widget.sensors[i]['Value'],
                          status: (widget.sensors[i]['Status'] ?? '').toString(),
                          isDark: isDark,
                          delay: const Duration(milliseconds: 150),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),


          // Thanh rack ngang phía dưới
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 196,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.racks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final r = widget.racks[i];
                    final status = (r['Status'] ?? '').toString();
                    final percentVal = r['Percent'];
                    final percent = (percentVal is num)
                        ? percentVal.toDouble()
                        : double.tryParse('${percentVal ?? 0}') ?? 0.0;

                    return AnimatedBuilder(
                      animation: _glowCtrl,
                      builder: (_, __) => _RackCard(
                        name: (r['Name'] ?? '').toString(),
                        time: (r['Time'] ?? '').toString(),
                        modelName: (r['ModelName'] ?? '').toString(),
                        pcs: (r['Number'] ?? 0).toString(),
                        status: status,
                        percent: percent,
                        isDark: isDark,
                        glow: status.toLowerCase() == 'running' ? _glowCtrl.value : 0.0,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  String _formatTemp(dynamic v) {
    if (v == null) return '--°C';
    final d = (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
    final s = d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 1);
    return '$s°C';
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1;
    const cell = 48.0;
    for (double x = 0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SensorBadge extends StatelessWidget {
  final String text;
  final String status;
  final bool isDark;
  const _SensorBadge({required this.text, required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? Colors.black.withOpacity(.55) : Colors.white.withOpacity(.9);
    final fg = isDark ? Colors.white : const Color(0xFF0B2433);
    final border = status.toLowerCase() == 'online' ? Colors.lightGreenAccent : Colors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border.withOpacity(.8)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.15), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

class _RackCard extends StatefulWidget {
  final String name;
  final String time;
  final String modelName;
  final String pcs;
  final String status;
  final double percent;
  final bool isDark;
  final double glow;

  const _RackCard({
    required this.name,
    required this.time,
    required this.modelName,
    required this.pcs,
    required this.status,
    required this.percent,
    required this.isDark,
    required this.glow,
  });

  @override
  State<_RackCard> createState() => _RackCardState();
}

class _RackCardState extends State<_RackCard> with TickerProviderStateMixin {
  late final AnimationController _runCtrl;    // RUNNING: ping-pong
  late final AnimationController _finishCtrl; // FINISHED: left->right loop

  bool get _isRunning  => widget.status.toLowerCase() == 'running';
  bool get _isFinished => widget.status.toLowerCase() == 'finished';

  @override
  void initState() {
    super.initState();
    _runCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _finishCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

    if (_isRunning)  _runCtrl.repeat();
    if (_isFinished) _finishCtrl.repeat();
  }

  @override
  void didUpdateWidget(covariant _RackCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isRunning && !_runCtrl.isAnimating) {
      _runCtrl.repeat();
    } else if (!_isRunning && _runCtrl.isAnimating) {
      _runCtrl.stop();
    }

    if (_isFinished && !_finishCtrl.isAnimating) {
      _finishCtrl.repeat();
    } else if (!_isFinished && _finishCtrl.isAnimating) {
      _finishCtrl.stop();
    }
  }

  @override
  void dispose() {
    _runCtrl.dispose();
    _finishCtrl.dispose();
    super.dispose();
  }


  double get _progress {
    if (_isFinished) return 1.0;
    final p = (widget.percent / 100.0).clamp(0.0, 1.0);
    return 1.0 - p;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;

    final cardBg = _isFinished
        ? (widget.isDark ? const Color(0xFF155A33) : const Color(0xFFD9F2E3))
        : (widget.isDark ? const Color(0xFF0F3A44) : const Color(0xFFCFE7EF));

    final title = widget.isDark ? Colors.white : const Color(0xFF0B2433);
    final sub   = widget.isDark ? Colors.white70 : const Color(0xFF184B60);

    final statusColor = _isFinished
        ? const Color(0xFF2ECC71)
        : (_isRunning ? Colors.amber : Colors.blueGrey);

    final dotColor = _isFinished
        ? const Color(0xFF2ECC71)
        : (_isRunning ? Colors.amber : Colors.grey);

    final borderColor = _isFinished
        ? const Color(0xFF2ECC71).withOpacity(.35)
        : Colors.cyanAccent.withOpacity(.25);

    return Container(
      width: 176,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: (_isRunning && widget.glow > 0)
            ? [BoxShadow(color: Colors.amber.withOpacity(widget.glow), blurRadius: 16, spreadRadius: 2)]
            : (_isFinished ? [const BoxShadow(color: Color(0x402ECC71), blurRadius: 10, spreadRadius: 1)] : []),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: title, fontWeight: FontWeight.bold),
                ),
              ),
              Icon(Icons.circle, size: 8, color: dotColor),
            ],
          ),

          // Time
          Text(widget.time, style: TextStyle(fontSize: 26, color: title, fontWeight: FontWeight.w600)),

          // Model + Qty
          Text('${widget.modelName}   ${widget.pcs} PCS', style: TextStyle(color: sub, fontSize: 12)),

          // ===== Thanh tiến độ =====
          SizedBox(
            height: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Track nền
                  Container(color: widget.isDark ? Colors.white10 : Colors.black12),

                  // FINISHED
                  if (_isFinished) ...[
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 1.0,
                      child: Container(color: const Color(0xFF2ECC71)),
                    ),
                    AnimatedBuilder(
                      animation: _finishCtrl,
                      builder: (_, __) {
                        final t = _finishCtrl.value;
                        return Align(
                          alignment: Alignment(-1 + 2 * t, 0),
                          child: FractionallySizedBox(
                            widthFactor: 0.28,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.white.withOpacity(0.0),
                                    Colors.white.withOpacity(0.45),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  // RUNNING
                  if (_isRunning && progress > 0) ...[
                    // vùng amber còn lại
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(color: Colors.amber.withOpacity(.35)),
                    ),
                    // shine chạy qua lại trong vùng amber
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final shineWidth = width * 0.30;
                          final moveRange = (width - shineWidth).clamp(0.0, double.infinity);
                          return AnimatedBuilder(
                            animation: _runCtrl,
                            builder: (_, __) {
                              final t = _runCtrl.value;
                              final ping = (t < 0.5) ? t * 2 : (1 - (t - 0.5) * 2);
                              final offset = ping * moveRange;
                              return Stack(
                                children: [
                                  Positioned(
                                    left: offset,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: shineWidth,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFFFFF176), Color(0xFFFFC107), Color(0xFFFFA000)],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Status
          Text(
            _isFinished ? 'FINISHED' : (_isRunning ? 'RUNNING' : widget.status.toUpperCase()),
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, letterSpacing: .5),
          ),
        ],
      ),
    );
  }
}

class AnimatedSensorBadge extends StatefulWidget {
  final dynamic value;
  final String status;
  final bool isDark;
  final Duration delay;

  const AnimatedSensorBadge({
    super.key,
    required this.value,
    required this.status,
    required this.isDark,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedSensorBadge> createState() => _AnimatedSensorBadgeState();
}

class _AnimatedSensorBadgeState extends State<AnimatedSensorBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? Colors.black.withOpacity(.55) : Colors.white.withOpacity(.9);
    final fg = widget.isDark ? Colors.white : const Color(0xFF0B2433);
    final border = widget.status.toLowerCase() == 'online' ? Colors.lightGreenAccent : Colors.amber;

    final value = widget.value;
    final d = (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0;
    final tempStr = d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 1) + '°C';

    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border.withOpacity(.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(tempStr, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
