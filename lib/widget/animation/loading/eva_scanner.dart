import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'painters/sonar_painter.dart';
import 'painters/radar_sweep_painter.dart';
import 'parts/eye.dart';
import 'parts/hand.dart';

class EvaScanner extends StatefulWidget {
  const EvaScanner({super.key, this.size = 320});
  final double size;

  @override
  State<EvaScanner> createState() => _EvaScannerState();
}

class _EvaScannerState extends State<EvaScanner> with TickerProviderStateMixin {
  static const rotDur   = Duration(seconds: 4);
  static const wavesDur = Duration(milliseconds: 2600);
  static const sweepDur = Duration(seconds: 3);

  late final AnimationController _rotCtrl;   // xoay EVA + dịch mắt/tay
  late final AnimationController _wavesCtrl; // sóng âm
  late final AnimationController _sweepCtrl; // radar sweep 0..360

  late final Animation<double> _rotY;        // 0..25deg
  late final Animation<double> _eyeShift;    // -50%..-40%
  late final Animation<double> _handLeftY;   // 55->30
  late final Animation<double> _handRightY;  // 55->70

  @override
  void initState() {
    super.initState();
    _rotCtrl   = AnimationController(vsync: this, duration: rotDur)..repeat(reverse: true);
    _wavesCtrl = AnimationController(vsync: this, duration: wavesDur)..repeat();
    _sweepCtrl = AnimationController(vsync: this, duration: sweepDur)..repeat();

    _rotY       = Tween<double>(begin: 0,     end: 25).animate(_rotCtrl);
    _eyeShift   = Tween<double>(begin: -0.50, end: -0.40).animate(_rotCtrl);
    _handLeftY  = Tween<double>(begin: 55,    end: 30).animate(_rotCtrl);
    _handRightY = Tween<double>(begin: 55,    end: 70).animate(_rotCtrl);
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    _wavesCtrl.dispose();
    _sweepCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: AnimatedBuilder(
          animation: Listenable.merge([_rotCtrl, _wavesCtrl, _sweepCtrl]),
          builder: (context, _) {
            final rotYRad = _rotY.value * math.pi / 180.0;
            final evaMatrix = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(rotYRad);

            return Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Color(0xFF0A0A0A), Colors.black],
                      radius: 0.95, stops: [0, 1],
                    ),
                  ),
                ),

                // Sóng âm nền
                CustomPaint(
                  painter: SonarPainter(
                    t: _wavesCtrl.value,
                    rings: 6,
                    baseColor: const Color(0xFF8BE9FF),
                  ),
                ),

                // EVA
                Transform(
                  alignment: Alignment.center,
                  transform: evaMatrix,
                  child: _buildEva(),
                ),

                // Tia quét radar 360°
                CustomPaint(
                  painter: RadarSweepPainter(
                    angle: _sweepCtrl.value * 2 * math.pi,
                    color: const Color(0xFF9BDAEB).withOpacity(0.35),
                    widthRatio: 0.9,
                    sweepDeg: 42,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEva() {
    const headW = 96.0, headH = 64.0;
    const bodyW = 104.0, bodyH = 134.0;
    const eyeW  = 72.0, eyeH  = 44.0;

    return FittedBox(
      fit: BoxFit.contain,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        // ĐẦU
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: headW,
              height: headH,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft, end: Alignment.centerRight,
                  colors: [Colors.white, Color(0xFFBFC0C2)], stops: [0.45, 1],
                ),
              ),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.6, -0.8), radius: 1.0,
                    colors: [Colors.white24, Colors.transparent],
                  ),
                ),
              ),
            ),
            // Khoang mắt
            Positioned(
              left: headW * 0.5, top: headH * 0.55,
              child: Transform.translate(
                offset: Offset(_eyeShift.value * eyeW, -eyeH * 0.5),
                child: Container(
                  width: eyeW, height: eyeH,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C203C),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(color: Colors.white, blurRadius: 0, spreadRadius: 2),
                    ],
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Stack(children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [Colors.white10, Colors.transparent],
                        ),
                      ),
                    ),
                    // Mắt trái
                    Positioned(
                      left: 12, top: (eyeH - EyeWidget.size) / 2,
                      child: Transform.rotate(
                        angle: -65 * math.pi / 180,
                        child: const EyeWidget(mirror: false),
                      ),
                    ),
                    // Mắt phải
                    Positioned(
                      right: 12, top: (eyeH - EyeWidget.size) / 2,
                      child: Transform.rotate(
                        angle: 65 * math.pi / 180,
                        child: const EyeWidget(mirror: true),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // THÂN + tay + khiên AIOT
        SizedBox(
          width: bodyW,
          height: bodyH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: bodyW, height: bodyH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(46),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft, end: Alignment.centerRight,
                    colors: [Colors.white, Color(0xFFBFC0C2)], stops: [0.36, 1],
                  ),
                ),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.7, -0.6), radius: 1.1,
                      colors: [Colors.white24, Colors.transparent],
                    ),
                  ),
                ),
              ),

              // Khiên AIOT
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: bodyW * 0.6,
                  height: bodyW * 0.5,
                  decoration: BoxDecoration(
                    color: const Color(0x809BDAEB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x809BDAEB), blurRadius: 10, spreadRadius: 2),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'AIOT',
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold,
                        color: Colors.white, letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),

              // Tay trái
              Positioned(
                left: -24, top: 12,
                child: HandWidget(
                  width: 32, height: 88,
                  rotateZDeg: 10, rotateYDeg: _handLeftY.value,
                  leftToRight: false,
                ),
              ),
              // Tay phải
              Positioned(
                left: bodyW * 0.92, top: 12,
                child: HandWidget(
                  width: 32, height: 88,
                  rotateZDeg: -10, rotateYDeg: _handRightY.value,
                  leftToRight: true,
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}
