import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_factory/features/camera_test/service/scan_payload_extractor.dart';
import 'package:smart_factory/features/camera_test/model/scan_result.dart';

class ScanTestScreen extends StatefulWidget {
  const ScanTestScreen({Key? key}) : super(key: key);

  @override
  State<ScanTestScreen> createState() => _ScanTestScreenState();
}

class _ScanTestScreenState extends State<ScanTestScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    detectionTimeoutMs: 300,
    formats: const [
      BarcodeFormat.dataMatrix,
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
    ],
  );


  late AnimationController _anim;
  late Animation<double> _tween;

  // UI / state
  bool _isProcessing = false;
  bool _found = false;
  String _foundCode = "";
  bool _torchOn = false;

  // scan window parameters
  double _scanBoxScale = 0.7;
  static const double _minScale = 0.25;
  static const double _maxScale = 0.98;

  // multi-frame attempt control
  int _emptyFrameCount = 0;
  final int _maxEmptyFramesBeforeExpand = 3;
  final int _maxEmptyFramesBeforeReset = 8;

  int _candidateButNoDecodeCount = 0;
  final int _maxCandidateNoDecodeBeforeShrink = 3;

  static const double _scaleStep = 0.12;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _tween = CurvedAnimation(parent: _anim, curve: Curves.linear);
    _anim.repeat(reverse: true);

    _controller.start();
    _controller.toggleTorch();
    _torchOn = true;
  }


  @override
  void dispose() {
    _anim.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _setScanScale(double newScale) {
    final double clamped = newScale.clamp(_minScale, _maxScale);
    if ((clamped - _scanBoxScale).abs() > 0.005) {
      setState(() => _scanBoxScale = clamped);
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
    } catch (_) {
      // ignore
    }
    setState(() => _torchOn = !_torchOn);
  }

  // Reset scan internal counters & states
  void _resetScanState({bool keepFound = false}) {
    _isProcessing = false;
    _emptyFrameCount = 0;
    _candidateButNoDecodeCount = 0;
    if (!keepFound) {
      _found = false;
      _foundCode = "";
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Qr"),
        actions: [
          IconButton(
            tooltip: "Torch",
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
          ),
          IconButton(
            tooltip: "Restart scanner",
            icon: const Icon(Icons.replay),
            onPressed: () async {
              _resetScanState();
              try {
                await _controller.start();
              } catch (_) {}
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final rect = Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width * 0.75,
            height: size.width * 0.75,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              // SCAN
              MobileScanner(
                controller: _controller,
                scanWindow: rect,
                onDetect: (capture) async {
                  if (_found || _isProcessing) return;
                  _isProcessing = true;

                  try {
                    final barcodes = capture.barcodes;

                    if (barcodes.isEmpty) {
                      _emptyFrameCount++;

                      if (_emptyFrameCount >= _maxEmptyFramesBeforeExpand) {
                        if (_scanBoxScale < _maxScale - 0.01) {
                          _setScanScale(_scanBoxScale + _scaleStep);
                        }
                        _emptyFrameCount = 0;
                      }

                      if (_emptyFrameCount > _maxEmptyFramesBeforeReset) {
                        _emptyFrameCount = 0;
                        _isProcessing = false;
                      }
                      return;
                    }

                    String? sn;

                    for (final barcode in barcodes) {
                      final raw = barcode.rawValue;
                      if (raw == null || raw.isEmpty) continue;

                      final ScanResult result = ScanPayloadExtractor.extract(raw);

                      if (result.hasSerial) {
                        Navigator.pop(context, {
                          "serial": result.serial,
                          "model": result.model,
                        });
                      }

                      if (sn != null) break;
                    }

                    if (sn == null) {
                      _isProcessing = false;
                      return;
                    }

                    _found = true;
                    _foundCode = sn;

                    try {
                      await _controller.stop();
                    } catch (_) {}

                    if (!mounted) return;

                    Navigator.pop(context, {
                      "serial": sn,
                    });
                  } catch (_) {
                    _emptyFrameCount++;
                    _isProcessing = false;
                  }
                },
              ),

              //  OVERLAY
              AnimatedBuilder(
                animation: _tween,
                builder: (context, _) {
                  return IgnorePointer(
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _ScanOverlayPainter(
                        rect: rect,
                        t: _tween.value,
                      ),
                    ),
                  );
                },
              ),

              // MANUAL SN BUTTON
              Positioned(
                bottom: 110, // nằm trên slider
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context, {
                        "manual": true,
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        "Không quét được mã => ✍️ Vui lòng nhập thủ công",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              //  ZOOM BAR
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.zoom_out, color: Colors.white70),
                            Expanded(
                              child: Slider(
                                value: _scanBoxScale,
                                min: _minScale,
                                max: _maxScale,
                                divisions: 10,
                                label: "${(_scanBoxScale * 100).round()}%",
                                onChanged: (v) {
                                  setState(() {
                                    _scanBoxScale = v;
                                    _emptyFrameCount = 0;
                                    _candidateButNoDecodeCount = 0;
                                  });
                                },
                              ),
                            ),
                            const Icon(Icons.zoom_in, color: Colors.white70),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Overlay painter
class _ScanOverlayPainter extends CustomPainter {
  final Rect rect;
  final double t;

  _ScanOverlayPainter({required this.rect, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark outside
    final overlay = Paint()..color = Colors.black.withOpacity(0.55);
    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(18)));

    final diff = Path.combine(PathOperation.difference, full, hole);
    canvas.drawPath(diff, overlay);

    // White border
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      border,
    );

    // Scan yellow line
    final y = rect.top + rect.height * t;
    final scanLine = Paint()
      ..color = Colors.amber
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(rect.left + 10, y),
      Offset(rect.right - 10, y),
      scanLine,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.rect != rect;
  }
}
