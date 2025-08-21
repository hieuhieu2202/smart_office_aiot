import 'package:flutter/material.dart';
import '../../../../config/global_color.dart';

class PTHDashboardMachineDetail extends StatelessWidget {
  final Map data;
  const PTHDashboardMachineDetail({super.key, required this.data});

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'run':
      case 'running':
        return const Color(0xFF4CAF50);
      case 'idle':
        return const Color(0xFFF44336);
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final runtime = data['runtime'];
    final machines = runtime?['runtimeMachine'] as List? ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg;

    if (machines.isEmpty) {
      return Card(
        color: bgColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const SizedBox(
          height: 120,
          child: Center(child: Text('No data available')),
        ),
      );
    }

    return Card(
      color: bgColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: DefaultTabController(
          length: machines.length,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Machine Details",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                isScrollable: true,
                labelColor: Colors.blue[700],
                unselectedLabelColor: isDark ? Colors.white60 : Colors.grey[600],
                indicator: BoxDecoration(
                  color: isDark ? Colors.blue.withOpacity(0.18) : Colors.blue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                tabs: machines
                    .map<Widget>((m) => Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      m['machine'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ))
                    .toList(),
              ),
              const SizedBox(height: 7),
              SizedBox(
                height: 150,
                child: TabBarView(
                  children: machines.map<Widget>((m) {
                    final detailList = m['runtimeMachineData'] as List? ?? [];

                    // Gom tất cả time thành một mảng chung cho header cột
                    final Set<String> allTimes = {};
                    for (var stData in detailList) {
                      for (var r in stData['result'] ?? []) {
                        allTimes.add(r['time'].toString());
                      }
                    }
                    final List<String> timeList = allTimes.toList()
                      ..sort((a, b) {
                        final na = int.tryParse(a) ?? 0;
                        final nb = int.tryParse(b) ?? 0;
                        return na.compareTo(nb);
                      });

                    // Gom trạng thái
                    final statusList = detailList.map((e) => (e['status'] ?? '').toString()).toList();

                    // Map [status][time] = {'value':..., 'percent':...}
                    final Map<String, Map<String, Map<String, dynamic>>> statusTimeMap = {};
                    for (var stData in detailList) {
                      final status = (stData['status'] ?? '').toString();
                      statusTimeMap[status] = {};
                      for (var r in stData['result'] ?? []) {
                        final time = r['time'].toString();
                        statusTimeMap[status]![time] = {
                          'value': r['value'],
                          'percent': r['percentage'],
                        };
                      }
                    }

                    final fewCols = timeList.length <= 5;
                    final cellWidth = fewCols ? 100.0 : 78.0;

                    // === Đây là phần cố định cột "Status" ===
                    return SizedBox(
                      height: 120,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cột Status (Cố định)
                          Column(
                            children: [
                              Container(
                                width: cellWidth,
                                height: 36,
                                color: isDark ? Colors.blueGrey[900] : Colors.blue[50],
                                child: Center(
                                  child: Text("Status",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: fewCols ? 15 : 13),
                                  ),
                                ),
                              ),
                              ...statusList.map((status) => Container(
                                width: cellWidth,
                                height: 44,
                                color: Colors.transparent,
                                child: Center(
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _statusColor(status),
                                      fontSize: fewCols ? 14 : 12,
                                    ),
                                  ),
                                ),
                              )),
                            ],
                          ),
                          // Cuộn ngang các cột còn lại
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Column(
                                children: [
                                  Row(
                                    children: timeList.map((t) =>
                                        Container(
                                          width: cellWidth,
                                          height: 36,
                                          color: isDark ? Colors.blueGrey[900] : Colors.blue[50],
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  t,
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: fewCols ? 14 : 12),
                                                ),
                                                const Text("Minutes / %", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                              ],
                                            ),
                                          ),
                                        )).toList(),
                                  ),
                                  ...statusList.map((status) => Row(
                                    children: timeList.map((t) {
                                      final cell = statusTimeMap[status]?[t];
                                      final value = cell?['value'] ?? '--';
                                      final percent = cell?['percent'] ?? '--';
                                      return Container(
                                        width: cellWidth,
                                        height: 44,
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              value.toString(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _statusColor(status),
                                                fontSize: fewCols ? 16 : 13,
                                              ),
                                            ),
                                            Text(
                                              "$percent%",
                                              style: TextStyle(
                                                color: Colors.blue,
                                                fontSize: fewCols ? 13 : 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
