import 'dart:async';
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
  bool _hasResult = false;
  String? _partNumber;
  String? _serialNumber;
  bool _torchOn = false;

  // Short-lived scan session (collect barcodes within a single label window).
  static const Duration _scanSessionWindow = Duration(milliseconds: 700);
  bool _sessionActive = false;
  int _sessionId = 0;
  DateTime? _sessionDeadline;
  Timer? _sessionTimer;
  final Set<String> _sessionValues = {};

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
    _sessionTimer?.cancel();
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
    _sessionTimer?.cancel();
    _resetScanSession();
    if (!keepFound) {
      _hasResult = false;
      _partNumber = null;
      _serialNumber = null;
    }
  }

  // Start a short-lived session to collect all barcodes from the same label.
  void _startScanSession() {
    _sessionId += 1;
    _sessionActive = true;
    _sessionValues.clear();
    _partNumber = null;
    _serialNumber = null;
    _sessionDeadline = DateTime.now().add(_scanSessionWindow);

    _sessionTimer?.cancel();
    final int currentSessionId = _sessionId;
    _sessionTimer = Timer(_scanSessionWindow, () {
      if (!mounted) return;
      if (_hasResult) return;
      if (_sessionId != currentSessionId) return;
      _resetScanSession();
    });
  }

  // Discard session data and continue scanning for a fresh label.
  void _resetScanSession() {
    _sessionActive = false;
    _sessionValues.clear();
    _partNumber = null;
    _serialNumber = null;
    _sessionDeadline = null;
  }

  bool _isSessionExpired() {
    final deadline = _sessionDeadline;
    if (!_sessionActive || deadline == null) return false;
    return DateTime.now().isAfter(deadline);
  }

  bool _isPartNumber(String value) {
    final hasLetter = RegExp(r"[A-Za-z]").hasMatch(value);
    final hasSeparator = value.contains("-") || value.contains("_");
    return hasLetter && hasSeparator;
  }

  bool _isSerialNumber(String value) {
    return RegExp(r"^[0-9]{8,}$").hasMatch(value);
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
                  if (_hasResult) return;

                  try {
                    final barcodes = capture.barcodes;

                    // ---------- NO BARCODE IN FRAME ----------
                    if (barcodes.isEmpty) {
                      _emptyFrameCount++;

                      if (_emptyFrameCount >= _maxEmptyFramesBeforeExpand) {

                        if (_scanBoxScale < _maxScale - 0.01) {
                          _setScanScale(_scanBoxScale + _scaleStep);
                        }
                        _emptyFrameCount = 0; // reset counter after expanding
                      }

                      if (_emptyFrameCount > _maxEmptyFramesBeforeReset) {
                        _emptyFrameCount = 0;
                        _isProcessing = false;
                      }
                      return;
                    }

                    // ---------- HAVE BARCODE ----------
                    if (_sessionActive && _isSessionExpired()) {
                      _resetScanSession();
                    }

                    if (!_sessionActive) {
                      _startScanSession();
                    }

                    bool anyDecoded = false;

                    for (final barcode in barcodes) {
                      final bcRaw = barcode.rawValue ?? "";
                      if (bcRaw.isEmpty) continue;
                      anyDecoded = true;

                      if (_sessionValues.add(bcRaw)) {
                        if (_partNumber == null && _isPartNumber(bcRaw)) {
                          _partNumber = bcRaw;
                        }

                        if (_serialNumber == null && _isSerialNumber(bcRaw)) {
                          _serialNumber = bcRaw;
                        }
                      }
                    }

                    if (!anyDecoded) {
                      _candidateButNoDecodeCount++;
                      if (_candidateButNoDecodeCount >= _maxCandidateNoDecodeBeforeShrink) {
                        if (_scanBoxScale > _minScale + 0.01) {
                          _setScanScale(_scanBoxScale - _scaleStep);
                        }
                        _candidateButNoDecodeCount = 0;
                      }
                      return;
                    }

                    if (_partNumber == null || _serialNumber == null) {
                      return;
                    }

                    _sessionTimer?.cancel();
                    _hasResult = true;

                    try {
                      await _controller.stop();
                    } catch (_) {}
                    if (!mounted) return;

                    Navigator.pop(context, {
                      "partNumber": _partNumber,
                      "serialNumber": _serialNumber,
                    });
                  } catch (e) {
                    // swallow, keep scanning
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
                        // status
                        // Text(
                        //   _found ? "Found: $_foundCode" : "Move camera to QR/barcode - adjust scan box to help detect small codes",
                        //   style: const TextStyle(color: Colors.white70),
                        // ),
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

                        const SizedBox(height: 4),

                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: [
                        //     ElevatedButton.icon(
                        //       style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        //       onPressed: _toggleTorch,
                        //       icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
                        //       label: Text(_torchOn ? "Torch on" : "Torch off"),
                        //     ),
                        //
                        //     ElevatedButton.icon(
                        //       onPressed: () async {
                        //         _resetScanState();
                        //         try {
                        //           await _controller.start();
                        //         } catch (_) {}
                        //       },
                        //       icon: const Icon(Icons.refresh),
                        //       label: const Text("Retry"),
                        //     ),
                        //   ],
                        // ),
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
