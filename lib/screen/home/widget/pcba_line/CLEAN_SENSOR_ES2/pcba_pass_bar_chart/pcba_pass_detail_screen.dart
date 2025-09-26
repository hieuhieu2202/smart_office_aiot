import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/widget/animation/loading/eva_loading_view.dart';

import '../../../../controller/pcba_line_controller.dart';
import 'pcba_pass_detail_bar_chart.dart';

class PcbaPassDetailScreen extends StatefulWidget {
  final PcbaLineDashboardController controller;
  final DateTime selectedDate;

  const PcbaPassDetailScreen({
    super.key,
    required this.controller,
    required this.selectedDate,
  });

  @override
  State<PcbaPassDetailScreen> createState() => _PcbaPassDetailScreenState();
}

class _PcbaPassDetailScreenState extends State<PcbaPassDetailScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    await widget.controller.fetchMachineChartDataForDate(widget.selectedDate);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text('Pass Quantity Detail'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const EvaLoadingView(size: 260)
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '≫ Pass Quantity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                final data = c.machineChartData;
                if (data.isEmpty) {
                  return const Center(
                    child: Text('No data',
                        style: TextStyle(color: Colors.white)),
                  );
                }
                return PcbaPassDetailBarChart(machineData: data);
              }),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
