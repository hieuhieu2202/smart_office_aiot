import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/pth_avi_controller.dart';

class PthAviKpiHeader extends StatelessWidget {
  final PthAviController controller;

  const PthAviKpiHeader({super.key, required this.controller});

  Widget _buildKpiCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildKpiCard("PASS", controller.totalPass.value.toString(), Colors.green),
        _buildKpiCard("FAIL", controller.totalFail.value.toString(), Colors.red),
        _buildKpiCard("YIELD (%)", controller.yieldPercent.value.toStringAsFixed(2), Colors.blue),
        _buildKpiCard("CYCLE TIME", controller.avgCycleTime.value.toStringAsFixed(1), Colors.orange),
      ],
    ));
  }
}
