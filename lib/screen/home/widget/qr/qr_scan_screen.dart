import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:smart_factory/config/ApiConfig.dart';
import 'package:smart_factory/screen/home/widget/qr/FixtureDetailScreen.dart';
import 'package:smart_factory/screen/navbar/controller/navbar_controller.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({Key? key}) : super(key: key);

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 700,
    formats: const [BarcodeFormat.qrCode],
  );

  final navbarController = Get.find<NavbarController>();

  bool _isProcessing = false;
  bool _showScanner = true;

  late final AnimationController _scanAnim;
  late final Animation<double> _scanTween;

  @override
  void initState() {
    super.initState();
    _scanAnim =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _scanTween = CurvedAnimation(parent: _scanAnim, curve: Curves.linear);
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    controller.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // Parse linh hoạt: hỗ trợ model=&station= (đã URL-encode) và các phân tách # / _ |
  ({String model, String station})? _parseQr(String code) {
    if (code.isEmpty) return null;
    final raw = code
        .trim()
        .replaceFirst(RegExp(r'^\s*QR:\s*', caseSensitive: false), '');
    final lower = raw.toLowerCase();

    // Dạng query string
    if (lower.contains('model=') && lower.contains('station=')) {
      final parts = raw.split(RegExp(r'[&;]'));
      String? model, station;
      for (final p in parts) {
        final kv = p.split('=');
        if (kv.length == 2) {
          final k = kv[0].trim().toLowerCase();
          final v = kv[1].trim();
          if (k == 'model' || k == 'modelname') {
            model = Uri.decodeComponent(v); // decode để không bị double-encode
          }
          if (k == 'station' || k == 'stationname') {
            station = Uri.decodeComponent(v);
          }
        }
      }
      if ((model ?? '').isNotEmpty && (station ?? '').isNotEmpty) {
        return (model: model!, station: station!);
      }
    }

    // Dạng tách theo ký tự
    const ds = ['#', '/', '_', '|'];
    for (final d in ds) {
      if (raw.contains(d)) {
        final parts = raw.split(d);
        if (parts.length >= 2) {
          final model = parts[0].trim();
          final station = parts[1].trim();
          if (model.isNotEmpty && station.isNotEmpty) {
            return (model: model, station: station);
          }
        }
      }
    }
    return null;
  }

  Future<void> _handleCode(String code) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final parsed = _parseQr(code);
      if (parsed == null) {
        debugPrint("QR không hợp lệ, raw=$code");
        return;
      }

      final model = parsed.model;
      final station = parsed.station;

      final url = Uri.parse(
        '${ApiConfig.fixtureEndpoint}'
            '?model=${Uri.encodeComponent(model)}'
            '&station=${Uri.encodeComponent(station)}',
      );
      debugPrint('[QR] GET $url');

      final response = await http.get(url);
      if (!mounted) return;

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        final bool ok = decoded is Map &&
            (decoded['success'] == true || decoded['Success'] == true) &&
            (decoded['data'] != null || decoded['Data'] != null);

        final data = decoded is Map
            ? (decoded['data'] ?? decoded['Data'])
            : null;

        if (ok && data != null && data is Map<String, dynamic>) {
          setState(() => _showScanner = false);
          await controller.stop();

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FixtureDetailScreen(
                model: model,
                station: station,
                data: data,
              ),
            ),
          );

          if (!mounted) return;
          setState(() => _showScanner = true);
          await controller.start();
        } else {
          debugPrint(
              "Không tìm thấy thông tin cho QR này. body=${response.body}");
        }
      } else if (response.statusCode == 204) {
        debugPrint("Không có dữ liệu (204).");
      } else {
        _showSnack("Lỗi server: HTTP ${response.statusCode}");
        debugPrint('Body: ${response.body}');
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
          actions: [
            IconButton(
                icon: const Icon(Icons.flash_on),
                onPressed: () => controller.toggleTorch(),
                tooltip: 'Bật/tắt đèn'),
            IconButton(
                icon: const Icon(Icons.cameraswitch),
                onPressed: () => controller.switchCamera(),
                tooltip: 'Đổi camera'),
          ],
        ),
        body: _showScanner
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
                  controller: controller,
                  scanWindow: scanRect,
                  onDetect: (capture) async {
                    if (_isProcessing) return;

                    for (final b in capture.barcodes) {
                      final String? value = b.rawValue;
                      if (value == null || value.isEmpty) continue;

                      // giữ UI cũ, chỉ thêm parse linh hoạt
                      final parsed = _parseQr(value);
                      if (parsed == null) continue;

                      await controller.stop();
                      await _handleCode(value);
                      break;
                    }
                  },
                ),
                // === Overlay: nền tối + khung bo góc + vạch vàng chạy ===
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
}

/// Overlay: nền tối, khung bo góc, vạch vàng chạy lên/xuống.
class _ScanOverlayPainter extends CustomPainter {
  final Rect rect;
  final double t;

  _ScanOverlayPainter({required this.rect, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // overlay tối “đục lỗ” phần khung
    final overlay = Paint()..color = Colors.black.withOpacity(0.5);
    final pathScreen =
    Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final pathHole =
    Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));
    final diff =
    Path.combine(PathOperation.difference, pathScreen, pathHole);
    canvas.drawPath(diff, overlay);

    // viền khung trắng
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(16)), border);

    // vạch vàng chạy
    final scanY = rect.top + rect.height * t;
    final scanLine = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawLine(
        Offset(rect.left + 8, scanY), Offset(rect.right - 8, scanY), scanLine);
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter old) {
    return old.t != t || old.rect != rect;
  }
}
