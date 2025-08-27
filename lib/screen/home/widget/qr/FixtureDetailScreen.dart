import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$model - $station",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
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
              _buildRow("File", _str("File_Name"), theme),
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
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
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
}
