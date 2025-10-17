import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_factory/config/ApiConfig.dart';
import 'package:smart_factory/screen/home/widget/qr/FixtureDetailScreen.dart';
import 'package:smart_factory/screen/home/widget/qr/ShieldingBoxDetailScreen.dart';

import 'package:smart_factory/screen/navbar/controller/navbar_controller.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({Key? key}) : super(key: key);

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;

  final navbarController = Get.find<NavbarController>();

  bool _isProcessing = false;
  bool _showScanner = true;
  late final bool _scannerSupported;

  late final AnimationController _scanAnim;
  late final Animation<double> _scanTween;

  @override
  void initState() {
    super.initState();
    _scannerSupported = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (_scannerSupported) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 700,
        formats: const [BarcodeFormat.qrCode],
      );
    } else {
      _showScanner = false;
    }
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanTween = CurvedAnimation(parent: _scanAnim, curve: Curves.linear);
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  ({String model, String station, String? mac})? _parseQr(String code) {
    if (code.isEmpty) return null;
    final raw = code.trim().replaceFirst(
      RegExp(r'^\s*QR:\s*', caseSensitive: false),
      '',
    );

    //  Query string: an toàn cho mọi ký tự đặc biệt ---
    final lower = raw.toLowerCase();
    final hasModelKey = lower.contains('model=');
    final hasStationKey = lower.contains('station=');
    if (hasModelKey && hasStationKey) {
      final q = () {
        final qmark = raw.indexOf('?');
        if (qmark >= 0 && qmark < raw.length - 1)
          return raw.substring(qmark + 1);
        return raw;
      }();

      final Map<String, String> kv = {};
      for (final seg in q.split(RegExp(r'[&;]'))) {
        final idx = seg.indexOf('=');
        if (idx <= 0) continue;
        final key = seg.substring(0, idx).trim().toLowerCase();
        final val = seg.substring(idx + 1);
        String decoded;
        try {
          decoded = Uri.decodeComponent(val);
        } catch (_) {
          decoded = val;
        }
        kv[key] = decoded;
      }

      String? model = kv['model'] ?? kv['modelname'];
      String? station = kv['station'] ?? kv['stationname'];
      String? mac = kv['mac'] ?? kv['sheildingmac'] ?? kv['shieldingmac'];

      if ((model ?? '').isNotEmpty && (station ?? '').isNotEmpty) {
        return (
          model: model!.trim(),
          station: station!.trim(),
          mac: (mac ?? '').trim().isEmpty ? null : mac!.trim(),
        );
      }
    }

    // Fallback: tách theo ký tự (giữ chuẩn cũ của Fixture) ---
    const seps = ['#', '/', '_', '|'];
    for (final d in seps) {
      if (raw.contains(d)) {
        final parts =
            raw
                .split(d)
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
        if (parts.length >= 2) {
          final model = parts[0];
          final station = parts[1];
          final mac = parts.length >= 3 ? parts[2] : null;
          if (model.isNotEmpty && station.isNotEmpty) {
            return (
              model: model,
              station: station,
              mac: mac?.isNotEmpty == true ? mac : null,
            );
          }
        }
      }
    }

    return null;
  }

  // ====== ROUTER: có mac -> SheildingBox; không có mac -> Fixture ======
  Future<void> _handleCode(String code) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final parsed = _parseQr(code);
      if (parsed == null) {
        _showSnack("QR không hợp lệ.");
        return;
      }

      final model = parsed.model;
      final station = parsed.station;
      final mac = parsed.mac;

      late final Uri url;
      late final String target; // 'fixture' | 'shielding'

      if (mac != null && mac.isNotEmpty) {
        // SheildingBox (3 tham số)
        url = Uri.parse(
          '${ApiConfig.shieldingEndpoint}'
          '?model=${Uri.encodeQueryComponent(model)}'
          '&station=${Uri.encodeQueryComponent(station)}'
          '&mac=${Uri.encodeQueryComponent(mac)}',
        );
        target = 'shielding';
      } else {
        // Fixture (2 tham số)
        url = Uri.parse(
          '${ApiConfig.fixtureEndpoint}'
          '?model=${Uri.encodeQueryComponent(model)}'
          '&station=${Uri.encodeQueryComponent(station)}',
        );
        target = 'fixture';
      }

      final res = await http.get(url, headers: {'Accept': 'application/json'});
      if (!mounted) return;

      if (res.statusCode != 200 || res.body.isEmpty) {
        _showSnack('Lỗi server: HTTP ${res.statusCode}');
        return;
      }

      final body = jsonDecode(res.body);
      final success =
          (body is Map) && (body['success'] == true || body['Success'] == true);
      final data = (body is Map) ? (body['data'] ?? body['Data']) : null;

      if (!success || data == null) {
        _showSnack(
          body is Map && body['message'] != null
              ? body['message'].toString()
              : 'Không tìm thấy dữ liệu.',
        );
        return;
      }

      setState(() => _showScanner = false);
      if (_controller != null) {
        await _controller!.stop();
      }

      if (target == 'fixture') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => FixtureDetailScreen(
                  model: model,
                  station: station,
                  data: Map<String, dynamic>.from(data),
                ),
          ),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ShieldingBoxDetailScreen(
                  data: Map<String, dynamic>.from(data),
                ),
          ),
        );
      }

      if (!mounted) return;
      setState(() => _showScanner = true);
      if (_controller != null) {
        await _controller!.start();
      }
    } catch (e) {
      _showSnack("Lỗi kết nối: $e");
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        navbarController.changTab(0);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Quét QR"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => navbarController.changTab(0),
          ),
          actions: _scannerSupported
              ? [
                  IconButton(
                    icon: const Icon(Icons.flash_on),
                    onPressed: () => _controller?.toggleTorch(),
                    tooltip: 'Bật/tắt đèn',
                  ),
                  IconButton(
                    icon: const Icon(Icons.cameraswitch),
                    onPressed: () => _controller?.switchCamera(),
                    tooltip: 'Đổi camera',
                  ),
                ]
              : null,
        ),
        body: !_scannerSupported
            ? _buildUnsupportedView()
            : _showScanner
                ? LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    final double boxSize = size.shortestSide * 0.68;
                    final Rect scanRect = Rect.fromCenter(
                      center: Offset(size.width / 2, size.height / 2),
                      width: boxSize,
                      height: boxSize,
                    );

                    return Stack(
                      children: [
                        MobileScanner(
                          controller: _controller!,
                          scanWindow: scanRect,
                          onDetect: (capture) async {
                            if (_isProcessing) return;

                            for (final b in capture.barcodes) {
                              final String? value = b.rawValue;
                              if (value == null || value.isEmpty) continue;

                              final parsed = _parseQr(value);
                              if (parsed == null) continue;

                              if (_controller != null) {
                                await _controller!.stop();
                              }
                              await _handleCode(value);
                              break;
                            }
                          },
                        ),
                        AnimatedBuilder(
                          animation: _scanTween,
                          builder: (context, _) {
                            return IgnorePointer(
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: _ScanOverlayPainter(
                                  rect: scanRect,
                                  t: _scanTween.value,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                )
                : const Center(child: Text("Đang tạm dừng camera...")),
      ),
    );
  }

  Widget _buildUnsupportedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Icon(Icons.desktop_windows_rounded, size: 64, color: Colors.blueGrey),
            SizedBox(height: 20),
            Text(
              'Tính năng quét QR hiện chỉ hỗ trợ trên điện thoại.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              'Vui lòng sử dụng ứng dụng trên Android hoặc iOS để tiếp tục.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ====== Overlay======
class _ScanOverlayPainter extends CustomPainter {
  final Rect rect;
  final double t;

  _ScanOverlayPainter({required this.rect, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black.withOpacity(0.5);
    final pathScreen =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final pathHole =
        Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));
    final diff = Path.combine(PathOperation.difference, pathScreen, pathHole);
    canvas.drawPath(diff, overlay);

    // viền
    final border =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      border,
    );

    // vạch vàng chạy
    final scanY = rect.top + rect.height * t;
    final scanLine =
        Paint()
          ..color = Colors.amber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
    canvas.drawLine(
      Offset(rect.left + 8, scanY),
      Offset(rect.right - 8, scanY),
      scanLine,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter old) {
    return old.t != t || old.rect != rect;
  }
}
