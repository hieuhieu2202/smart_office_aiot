import 'package:flutter/material.dart';
import 'package:smart_factory/config/ApiConfig.dart';
import 'package:smart_factory/screen/home/widget/qr/pdf_viewer_screen.dart';

class FixtureDetailScreen extends StatelessWidget {
  final String model;
  final String station;
  final Map<String, dynamic> data;

  const FixtureDetailScreen({
    super.key,
    required this.model,
    required this.station,
    required this.data,
  });

  String _str(String key) {
    final v = data[key];
    return (v == null || v.toString().trim().isEmpty) ? '-' : v.toString();
  }

  /// Trả về URL PDF (xử lý cả khi API trả full URL)
  String _buildPdfUrl(String fileName) {
    final clean = fileName.trim();
    final isFull = clean.startsWith('http://') || clean.startsWith('https://');
    final url = isFull ? clean : '${ApiConfig.logFileBase}/${Uri.encodeComponent(clean)}';
    debugPrint('[Fixture] PDF URL = $url');
    return url;
  }

  /// Lấy tên file từ API và log để đối chiếu
  String _apiFileName() {
    final raw = _str("File_Name");
    final clean = raw.trim();
    debugPrint('[Fixture] API File_Name (raw)  = "$raw"');
    debugPrint('[Fixture] API File_Name (trim) = "$clean"');
    return clean;
  }

  void _openLogFile(BuildContext context) {
    final file = _apiFileName();
    if (file.isEmpty || file == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có file để mở')),
      );
      return;
    }
    final url = _buildPdfUrl(file);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(url: url, title: file),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("$model - $station", style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Column(
            children: [
              _buildRow("Model", _str("Model_Name"), theme),
              const Divider(height: 1),
              _buildRow("Group", _str("Group_Name"), theme),
              const Divider(height: 1),
              _buildRow("Station", _str("Station_Name"), theme),
              const Divider(height: 1),
              _buildRow("Ngày Calibration", _str("Calibration_Date"), theme),
              const Divider(height: 1),
              _buildRow("Ngày Kết thúc", _str("End_Date"), theme),
              const Divider(height: 1),
              _buildRow("Người tạo", _str("Create_People"), theme),
              const Divider(height: 1),
              _buildRow("Phân xưởng", _str("Part"), theme),
              const Divider(height: 1),
              _buildFileRow(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500, color: theme.colorScheme.primary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileRow(BuildContext context, ThemeData theme) {
    final file = _apiFileName();
    final hasFile = file.isNotEmpty && file != '-';

    return InkWell(
      onTap: hasFile ? () => _openLogFile(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                "File",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      file,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: hasFile ? Colors.blue : theme.colorScheme.onSurface,
                        decoration: hasFile ? TextDecoration.underline : TextDecoration.none,
                      ),
                    ),
                  ),
                  if (hasFile) const Icon(Icons.picture_as_pdf, size: 18, color: Colors.red),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
