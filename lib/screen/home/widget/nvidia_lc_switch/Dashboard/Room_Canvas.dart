import 'dart:math';
import 'package:flutter/material.dart';

typedef RackTapCallback = Future<void> Function(Map<String, dynamic> rack);

class RoomCanvas extends StatefulWidget {
  final List<Map<String, dynamic>> sensors;
  final List<Map<String, dynamic>> racks;
  final RackTapCallback? onRackTap;

  const RoomCanvas({
    super.key,
    required this.sensors,
    required this.racks,
    this.onRackTap,
  });

  @override
  State<RoomCanvas> createState() => _RoomCanvasState();
}

class _RoomCanvasState extends State<RoomCanvas> with TickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final AnimationController _lightCtrl;

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _lightCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _glowCtrl.stop();
    _glowCtrl.dispose();
    _lightCtrl.stop();
    _lightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Bảo vệ dữ liệu trống
    if (widget.sensors.isEmpty && widget.racks.isEmpty) {
      return const SizedBox.expand(
        child: Center(
          child: Text(
            "No racks to display",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
        constraints.hasBoundedWidth ? constraints.maxWidth : 400.0;
        final height =
        constraints.hasBoundedHeight ? constraints.maxHeight : 300.0;

        if (width <= 0 || height <= 0) {
          return const SizedBox.expand(
            child: Center(child: CircularProgressIndicator(strokeWidth: 1.8)),
          );
        }

        final isTablet = width < 1024 && width >= 600;
        final isMobile = width < 600;
        final isCompactMobile = isMobile && width < 360;
        final rackWidth = isMobile
            ? (isCompactMobile
                ? 132.0
                : width < 420
                    ? 140.0
                    : 150.0)
            : isTablet
                ? 170.0
                : 180.0;
        final rackHeight = isMobile
            ? (isCompactMobile
                ? 122.0
                : width < 420
                    ? 132.0
                    : 144.0)
            : isTablet
                ? 162.0
                : 170.0;

        Widget buildSensorStrip() {
          if (widget.sensors.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: EdgeInsets.only(top: isMobile ? 10 : 24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.sensors.length, (i) {
                  final s = widget.sensors[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: AnimatedSensorBadge(
                      value: s['Value'],
                      status: (s['Status'] ?? '').toString(),
                      isDark: isDark,
                      delay: Duration(milliseconds: 150 * i),
                    ),
                  );
                }),
              ),
            ),
          );
        }

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Nền neon
              AnimatedBuilder(
                animation: _lightCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _NeonRoomPainter(isDark, _lightCtrl.value),
                  size: Size(width, height),
                ),
              ),

              if (isMobile)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (widget.sensors.isNotEmpty) buildSensorStrip(),
                        if (widget.sensors.isNotEmpty)
                          const SizedBox(height: 12),
                        const Spacer(),
                        if (widget.racks.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildRackGrid(
                                true, isTablet, rackWidth, rackHeight, isDark),
                          ),
                      ],
                    ),
                  ),
                )
              else ...[
                if (widget.sensors.isNotEmpty)
                  Align(
                    alignment: Alignment.topCenter,
                    child: buildSensorStrip(),
                  ),
                if (widget.racks.isNotEmpty)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildRackGrid(
                          false, isTablet, rackWidth, rackHeight, isDark),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ===== BUILD RACK GRID =====
  Widget _buildRackGrid(bool isMobile, bool isTablet, double rackWidth,
      double rackHeight, bool isDark) {
    final rackCards = widget.racks
        .map((r) => RackCard(
              name: r['Name'] ?? '',
              time: r['Time'] ?? '',
              modelName: r['ModelName'] ?? '',
              pcs: '${r['Number'] ?? 0}',
              status: r['Status'] ?? '',
              percent: (r['Percent'] ?? 0).toDouble(),
              isDark: isDark,
              glowCtrl: _glowCtrl,
              width: rackWidth,
              height: rackHeight,
              onTap: widget.onRackTap == null
                  ? null
                  : () {
                      widget.onRackTap!(r);
                    },
            ))
        .toList();

    if (isMobile) {
      return SizedBox(
        height: rackHeight + 28,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemCount: rackCards.length,
          itemBuilder: (_, i) => rackCards[i],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 20,
          children: rackCards,
        ),
      );
    }
  }
}

//
// ================== BACKGROUND PAINTER ==================
class _NeonRoomPainter extends CustomPainter {
  final bool isDark;
  final double t;
  _NeonRoomPainter(this.isDark, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    final w = size.width;
    final h = size.height;
    final mid = w / 2;

    final base = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [
          const Color(0xFF000E16),
          const Color(0xFF012B3C),
          const Color(0xFF00354F)
        ]
            : [
          const Color(0xFFCCDEE4),
          const Color(0xFFBAD5DD),
          const Color(0xFFA8CBD6)
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), base);

    final offsetX = sin(t * 2 * pi) * (w / 3) + mid;
    final lightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? Colors.cyanAccent : Colors.lightBlueAccent)
              .withOpacity(0.45),
          Colors.transparent,
        ],
      ).createShader(
          Rect.fromCircle(center: Offset(offsetX, h * 0.4), radius: w * 0.9))
      ..blendMode = BlendMode.plus;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), lightPaint);

    final linePaint = Paint()
      ..color = (isDark ? Colors.cyanAccent : Colors.blueAccent)
          .withOpacity(isDark ? 0.25 : 0.5)
      ..strokeWidth = 1.0;

    const depth = 340.0;
    const step = 70.0;

    // floor grid
    for (double y = 0; y <= depth; y += step) {
      final ratio = y / depth;
      final leftX = ratio * w * 0.18;
      final rightX = w - ratio * w * 0.18;
      final yPos = h - (ratio * 300);
      canvas.drawLine(Offset(leftX, yPos), Offset(rightX, yPos), linePaint);
    }

    for (double x = 0; x <= w; x += step) {
      final path = Path()
        ..moveTo(x, h)
        ..lineTo(mid + (x - mid) * 0.65, h - depth);
      canvas.drawPath(path, linePaint);
    }

    final floorGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? Colors.cyanAccent : Colors.blueAccent)
              .withOpacity(isDark ? 0.3 : 0.5),
          Colors.transparent,
        ],
        center: Alignment.bottomCenter,
        radius: 1.2,
      ).createShader(Rect.fromLTWH(0, h - 200, w, 200))
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 40);
    canvas.drawRect(Rect.fromLTWH(0, h - 200, w, 200), floorGlow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

//
// ================== SENSOR BADGE ==================
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
      if (mounted && !_ctrl.isAnimating) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    if (_ctrl.isAnimating) _ctrl.stop();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.status.toLowerCase() == 'online'
        ? Colors.lightGreenAccent
        : Colors.amberAccent;
    final temp = double.tryParse(widget.value.toString()) ?? 0;
    final tempStr = '${temp.toStringAsFixed(1)}°C';

    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: widget.isDark
              ? Colors.black.withOpacity(.55)
              : Colors.white.withOpacity(.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor.withOpacity(.8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          tempStr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: widget.isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

//
// ================== RACK CARD ==================
class RackCard extends StatefulWidget {
  final String name;
  final String time;
  final String modelName;
  final String pcs;
  final String status;
  final double percent;
  final bool isDark;
  final AnimationController glowCtrl;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const RackCard({
    super.key,
    required this.name,
    required this.time,
    required this.modelName,
    required this.pcs,
    required this.status,
    required this.percent,
    required this.isDark,
    required this.glowCtrl,
    required this.width,
    required this.height,
    this.onTap,
  });

  @override
  State<RackCard> createState() => _RackCardState();
}

class _RackCardState extends State<RackCard> with TickerProviderStateMixin {
  late final AnimationController _runCtrl;
  late final AnimationController _finishCtrl;

  bool get _isRunning => widget.status.toLowerCase() == 'running';
  bool get _isFinished => widget.status.toLowerCase() == 'finished';

  @override
  void initState() {
    super.initState();
    _runCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
    _finishCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    if (_runCtrl.isAnimating) _runCtrl.stop();
    if (_finishCtrl.isAnimating) _finishCtrl.stop();
    _runCtrl.dispose();
    _finishCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.percent / 100).clamp(0.0, 1.0);
    final baseColor =
    _isFinished ? const Color(0xFF007A3D) : const Color(0xFF0E354B);

    final glowOpacity = (0.25 + 0.35 * sin(widget.glowCtrl.value * 2 * pi))
        .clamp(0.0, 1.0) as double;

    final glow = _isRunning
        ? BoxShadow(
            color: Colors.amberAccent.withOpacity(glowOpacity),
            blurRadius: 18,
            spreadRadius: 5,
          )
        : BoxShadow(
            color: Colors.black.withOpacity(.3),
            blurRadius: 10,
            spreadRadius: 1,
          );

    final isCompactCard = widget.width < 145;
    final padding = EdgeInsets.all(isCompactCard ? 10 : 12);
    final headerSize = isCompactCard ? 12.0 : 13.0;
    final timeSize = isCompactCard ? 20.0 : 22.0;
    final detailSize = isCompactCard ? 10.5 : 11.0;
    final statusSize = isCompactCard ? 11.0 : 12.0;
    final barHeight = isCompactCard ? 7.0 : 8.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                baseColor.withOpacity(0.95),
                baseColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.cyanAccent.withOpacity(.3)),
            boxShadow: [glow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER =====
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: headerSize,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.circle,
                    size: 7,
                    color: _isFinished
                        ? Colors.greenAccent
                        : (_isRunning ? Colors.amber : Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _isFinished ? "00:00" : widget.time,
                style: TextStyle(
                  fontSize: timeSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.modelName} • ${widget.pcs} PCS',
                style: TextStyle(color: Colors.white70, fontSize: detailSize),
              ),
              const SizedBox(height: 8),

              // ===== PROGRESS BAR =====
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Stack(
                  children: [
                    Container(height: barHeight, color: Colors.white10),
                    if (_isRunning)
                      AnimatedBuilder(
                        animation: _runCtrl,
                        builder: (_, __) {
                          final t = _runCtrl.value;
                          final width = (progress * widget.width)
                              .clamp(0.0, widget.width);
                          final x = (t < 0.5 ? t : 1 - t) * (width - 50);
                          return Stack(
                            children: [
                              Container(
                                width: width,
                                height: barHeight,
                                color: Colors.amber.withOpacity(.3),
                              ),
                              Positioned(
                                left: x,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 50,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFFFF59D),
                                        Color(0xFFFFC107),
                                        Color(0xFFFFA000),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            ],
                          );
                        },
                      ),
                    if (_isFinished)
                      AnimatedBuilder(
                        animation: _finishCtrl,
                        builder: (_, __) {
                          final t = _finishCtrl.value;
                          final x = t * (widget.width - 40);
                          return Stack(
                            children: [
                              Container(
                                  height: barHeight, color: Colors.greenAccent),
                              Positioned(
                                left: x,
                                child: Container(
                                  width: 40,
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0),
                                        Colors.white.withOpacity(.6),
                                        Colors.white.withOpacity(0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 6),
              Text(
                _isFinished ? "FINISHED" : "RUNNING",
                style: TextStyle(
                  color: _isFinished ? Colors.greenAccent : Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: statusSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
