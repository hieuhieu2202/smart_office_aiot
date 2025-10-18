import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 700,
    formats: const [BarcodeFormat.qrCode],
  );

  final navbarController = Get.find<NavbarController>();

  bool _isProcessing = false;
  bool _showScanner = true;
  bool _scannerAvailable = true;
  String? _scannerUnavailableMsg;

  late final AnimationController _scanAnim;
  late final Animation<double> _scanTween;

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scanTween = CurvedAnimation(parent: _scanAnim, curve: Curves.linear);

    _scannerAvailable = _isSupportedScannerPlatform();
    if (_scannerAvailable) {
      _scanAnim.repeat(reverse: true);
    } else {
      _scannerUnavailableMsg =
          'Thiết bị này không hỗ trợ camera để quét QR. Vui lòng sử dụng thiết bị có camera.';
    }
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    controller.dispose();
    super.dispose();
  }

  bool _isSupportedScannerPlatform() {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  void _handleScannerUnavailable([String? message]) {
    if (!_scannerAvailable || !mounted) return;
    setState(() {
      _scannerAvailable = false;
      _showScanner = false;
      _scannerUnavailableMsg = message ??
          'Không thể truy cập camera trên thiết bị này. Vui lòng kiểm tra lại.';
    });
    if (_scanAnim.isAnimating) {
      _scanAnim.stop();
    }
  }

  Future<bool> _tryStopScanner() async {
    if (!_scannerAvailable) return false;
    try {
      await controller.stop();
      return true;
    } on MissingPluginException {
      _handleScannerUnavailable(
          'Thiết bị không hỗ trợ chức năng quét QR hoặc chưa cài đặt camera.');
      return false;
    } on PlatformException catch (e) {
      _handleScannerUnavailable(
          'Không thể tạm dừng camera: ${e.message ?? e.code}');
      return false;
    }
  }

  Future<bool> _tryStartScanner() async {
    if (!_scannerAvailable) return false;
    try {
      await controller.start();
      return true;
    } on MissingPluginException {
      _handleScannerUnavailable(
          'Thiết bị không hỗ trợ chức năng quét QR hoặc chưa cài đặt camera.');
      return false;
    } on PlatformException catch (e) {
      _handleScannerUnavailable(
          'Không thể khởi động camera: ${e.message ?? e.code}');
      return false;
    }
  }

  Future<void> _toggleTorch() async {
    if (!_scannerAvailable) return;
    try {
      await controller.toggleTorch();
    } on MissingPluginException {
      _handleScannerUnavailable(
          'Thiết bị không hỗ trợ bật/tắt đèn flash cho chức năng quét QR.');
    } on PlatformException catch (e) {
      _showSnack('Không thể bật/tắt đèn: ${e.message ?? e.code}');
    }
  }

  Future<void> _switchCamera() async {
    if (!_scannerAvailable) return;
    try {
      await controller.switchCamera();
    } on MissingPluginException {
      _handleScannerUnavailable(
          'Thiết bị không hỗ trợ đổi camera cho chức năng quét QR.');
    } on PlatformException catch (e) {
      _showSnack('Không thể đổi camera: ${e.message ?? e.code}');
    }
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
      await _tryStopScanner();

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
      if (_scannerAvailable) {
        setState(() => _showScanner = true);
        await _tryStartScanner();
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
              onPressed: _scannerAvailable ? _toggleTorch : null,
              tooltip: 'Bật/tắt đèn',
            ),
            IconButton(
              icon: const Icon(Icons.cameraswitch),
              onPressed: _scannerAvailable ? _switchCamera : null,
              tooltip: 'Đổi camera',
            ),
          ],
        ),
        body: !_scannerAvailable
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    _scannerUnavailableMsg ??
                        'Camera không khả dụng trên thiết bị này.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
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
                          controller: controller,
                          scanWindow: scanRect,
                          errorBuilder: (context, error, child) {
                            final code = (error.errorCode ?? '').trim();
                            final details = (error.errorDetails ?? '').trim();
                            final joined = [code, details]
                                .where((element) => element.isNotEmpty)
                                .join(' - ');
                            final message = joined.isEmpty
                                ? 'Không thể khởi tạo camera trên thiết bị này.'
                                : 'Không thể khởi tạo camera: $joined';
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Text(
                                  message,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                          onDetect: (capture) async {
                            if (_isProcessing) return;

                            for (final b in capture.barcodes) {
                              final String? value = b.rawValue;
                              if (value == null || value.isEmpty) continue;

                              final parsed = _parseQr(value);
                              if (parsed == null) continue;

                              final stopped = await _tryStopScanner();
                              if (!stopped) return;
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
