import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanTestScreen extends StatefulWidget {
  const ScanTestScreen({Key? key}) : super(key: key);

  @override
  State<ScanTestScreen> createState() => _ScanTestScreenState();
}

class _ScanTestScreenState extends State<ScanTestScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    detectionTimeoutMs: 250,
    formats: BarcodeFormat.values,
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
        title: const Text("Quét QR"),
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
          final double boxSize = math.min(size.width * _scanBoxScale, 400);
          final rect = Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: boxSize,
            height: boxSize,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _controller,
                scanWindow: rect,
                onDetect: (capture) async {
                  if (_found) return;

                  try {
                    final barcodes = capture.barcodes;

                    // ---------- NO BARCODE IN FRAME ----------
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

                    // ---------- HAVE BARCODE ----------
                    String? snCandidate;

                    for (final barcode in barcodes) {
                      final raw = barcode.rawValue?.trim() ?? "";
                      if (raw.isEmpty) continue;

                      // BỎ PN (có dấu '-')
                      if (raw.contains('-')) continue;

                      // RULE SN: chữ + số, không '-', độ dài >= 8
                      if (RegExp(r'^[A-Z0-9]{8,}$').hasMatch(raw)) {
                        snCandidate = raw;
                        break;
                      }
                    }

                    // Chưa có SN → tiếp tục scan
                    if (snCandidate == null) {
                      return;
                    }

                    _found = true;
                    _foundCode = snCandidate;

                    try {
                      await _controller.stop();
                    } catch (_) {}

                    if (!mounted) return;

                    Navigator.pop(context, {
                      "serial": _foundCode,
                      "format": capture.barcodes.first.format.name,
                    });
                  } catch (_) {
                    _emptyFrameCount++;
                    _isProcessing = false;
                  }
                },
              ),

              // animated overlay
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
                                onChanged: (v) => setState(() => _scanBoxScale = v),
                              ),
                            ),
                            const Icon(Icons.zoom_in, color: Colors.white70),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  _ScanOverlayPainter({required this.rect, required this.t});

  final Rect rect;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bg = Paint()..color = Colors.black.withOpacity(0.45);
    final Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, bg);

    final Paint border = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)), border);

    // scanning line
    final Paint line = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2;
    final double y = rect.top + rect.height * t;
    canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), line);
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) {
    return oldDelegate.rect != rect || oldDelegate.t != t;
  }
}
