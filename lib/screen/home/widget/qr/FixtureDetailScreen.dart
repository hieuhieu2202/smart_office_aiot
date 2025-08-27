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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết $model - $station'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("Model: ${data['Model_Name']}"),
            Text("Group: ${data['Group_Name']}"),
            Text("Station: ${data['Station_Name']}"),
            Text("Ngày Calibration: ${data['Calibration_Date']}"),
            Text("Ngày Kết thúc: ${data['End_Date']}"),
            Text("Người tạo: ${data['Create_People']}"),
            Text("Phân xưởng: ${data['Part']}"),
            if (data['File_Name'] != null && data['File_Name'].toString().isNotEmpty)
              Text("File: ${data['File_Name']}"),
          ],
        ),
      ),
    );
  }
}
