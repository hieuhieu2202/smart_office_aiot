import 'dart:convert';
import 'dart:math' as math;
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (!_scannerAvailable) {
              return _buildUnavailableState(context, constraints);
            }
            if (!_showScanner) {
              return _buildPausedState(context, constraints);
            }
            return _buildResponsiveScanner(context, constraints);
          },
        ),
      ),
    );
  }

  Widget _buildResponsiveScanner(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    if (constraints.maxWidth < 600) {
      return _buildCompactScanner(context);
    }
    return _buildExpandedScanner(context, constraints);
  }

  Widget _buildCompactScanner(BuildContext context) {
    return _buildScannerStack();
  }

  Widget _buildExpandedScanner(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final double scannerWidth = math.max(
      math.min(constraints.maxWidth * 0.5, 560),
      360,
    );
    final double aspectRatio = 3 / 4;
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: scannerWidth,
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: _buildFramedScanner(),
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Quét QR trên màn hình lớn',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Giữ mã QR trước camera ở khoảng cách 15-20cm và đảm bảo khu vực quét được chiếu sáng tốt.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildInfoChip(
                              context,
                              icon: Icons.flash_on,
                              label: 'Bật/Tắt đèn',
                              onPressed: _scannerAvailable ? _toggleTorch : null,
                            ),
                            _buildInfoChip(
                              context,
                              icon: Icons.cameraswitch,
                              label: 'Đổi camera',
                              onPressed: _scannerAvailable ? _switchCamera : null,
                            ),
                            _buildInfoChip(
                              context,
                              icon: Icons.qr_code_scanner,
                              label: 'Tự động nhận diện',
                              onPressed: null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Divider(color: theme.dividerColor.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        Text(
                          'Mẹo quét thành công:',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildHintRow(
                          context,
                          icon: Icons.check_circle_outline,
                          text: 'Giữ tay chắc và tránh rung lắc khi đưa mã QR vào khung.',
                        ),
                        const SizedBox(height: 8),
                        _buildHintRow(
                          context,
                          icon: Icons.light_mode_outlined,
                          text: 'Đảm bảo khu vực đủ sáng hoặc bật đèn flash nếu cần.',
                        ),
                        const SizedBox(height: 8),
                        _buildHintRow(
                          context,
                          icon: Icons.phonelink_setup,
                          text: 'Nếu không thấy camera, hãy kiểm tra lại quyền truy cập thiết bị.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFramedScanner() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF3C72FF), Color(0xFF7A33FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33212121),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: _buildScannerStack(),
          ),
        ),
      ),
    );
  }

  Widget _buildScannerStack() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final double boxSize = size.shortestSide * 0.68;
        final Rect scanRect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: boxSize,
          height: boxSize,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: controller,
              scanWindow: scanRect,
              errorBuilder: (
                BuildContext context,
                MobileScannerException error,
              ) {
                final code = error.errorCode?.toString().trim() ?? '';
                final details = error.errorDetails?.toString().trim() ?? '';
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
                      style: Theme.of(context).textTheme.bodyLarge,
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
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    final buttonStyle = OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );

    if (onPressed == null) {
      return Chip(
        avatar: Icon(icon, size: 18, color: theme.colorScheme.primary),
        label: Text(label, style: theme.textTheme.bodyMedium),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor:
            theme.colorScheme.primary.withOpacity(theme.brightness == Brightness.dark ? 0.12 : 0.08),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: theme.textTheme.bodyMedium),
      style: buttonStyle,
    );
  }

  Widget _buildHintRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildUnavailableState(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final theme = Theme.of(context);
    final message = _scannerUnavailableMsg ??
        'Camera không khả dụng trên thiết bị này.';

    final card = Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy camera',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Vui lòng kết nối camera ngoài hoặc chuyển sang thiết bị di động để tiếp tục quét.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    if (constraints.maxWidth < 600) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: card,
      ),
    );
  }

  Widget _buildPausedState(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final theme = Theme.of(context);
    final message = 'Đang tạm dừng camera...';

    final content = Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pause_circle_filled,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Nhấn vào biểu tượng quay lại để trở về trang chủ hoặc chờ hệ thống xử lý dữ liệu.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    if (constraints.maxWidth < 600) {
      return const Center(child: Text('Đang tạm dừng camera...'));
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: content,
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
