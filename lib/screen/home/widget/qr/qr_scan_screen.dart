import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

import 'package:smart_factory/screen/home/widget/qr/FixtureDetailScreen.dart';
import 'package:smart_factory/config/ApiConfig.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({Key? key}) : super(key: key);

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _handleCode(String code) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      debugPrint(">>> QR raw value: $code");

      // Chấp nhận định dạng "Model#Station" hoặc "Model/Station"
      final delimiter = code.contains('#')
          ? '#'
          : (code.contains('/') ? '/' : null);

      if (delimiter == null) {
        _showSnack("QR không hợp lệ: $code");
        return;
      }

      final parts = code.split(delimiter);
      if (parts.length < 2) {
        _showSnack("QR không hợp lệ (thiếu model/station): $code");
        return;
      }

      final model = parts[0].trim();
      final station = parts[1].trim();
      debugPrint(">>> Model: $model, Station: $station");

      final url = Uri.parse(
        '${ApiConfig.fixtureEndpoint}?model=${Uri.encodeComponent(model)}&station=${Uri.encodeComponent(station)}',
      );
      debugPrint(">>> URL gọi API: $url");

      final response = await http.get(url);
      debugPrint(">>> Status: ${response.statusCode}");

      if (!mounted) return;

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map &&
            decoded['success'] == true &&
            decoded['data'] != null) {
          await controller.stop(); // tránh quét lặp khi điều hướng

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FixtureDetailScreen(
                model: model,
                station: station,
                data: decoded['data'],
              ),
            ),
          );

          if (mounted) await controller.start(); // quay lại tiếp tục quét
        } else {
          _showSnack("Không tìm thấy thông tin cho QR.");
        }
      } else if (response.statusCode == 204) {
        _showSnack("Không có dữ liệu (204).");
      } else {
        _showSnack("Lỗi khi lấy dữ liệu từ server: ${response.statusCode}");
      }
    } catch (e) {
      _showSnack("Lỗi kết nối đến server: $e");
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quét QR"),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
            tooltip: 'Bật/tắt đèn',
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => controller.switchCamera(),
            tooltip: 'Đổi camera',
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        // onDetect nhận BarcodeCapture
        onDetect: (BarcodeCapture capture) async {
          for (final b in capture.barcodes) {
            final String? code = b.rawValue;
            if (code != null && code.isNotEmpty) {
              // tạm dừng để tránh quét nhiều lần
              await controller.stop();
              await _handleCode(code);
              if (mounted) await controller.start();
              break;
            }
          }
        },
      ),
    );
  }
}
