import 'package:flutter/material.dart';
import '../../../config/global_color.dart';
import '../../../config/global_text_style.dart';

class PTHDashboardMachineDetail extends StatelessWidget {
  final Map data;
  const PTHDashboardMachineDetail({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final runtime = data['runtime'];
    final machines = runtime?['runtimeMachine'] as List? ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (machines.isEmpty) {
      return Card(
        color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const SizedBox(
          height: 100,
          child: Center(child: Text('No data available')),
        ),
      );
    }

    return DefaultTabController(
      length: machines.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            isScrollable: true,
            labelColor: isDark ? GlobalColors.labelDark : GlobalColors.labelLight,
            tabs: machines.map<Widget>((m) => Tab(text: m['machine'].toString())).toList(),
          ),
          SizedBox(
            height: 180,
            child: TabBarView(
              children: machines.map<Widget>((m) {
                final detailList = m['runtimeMachineData'] as List? ?? [];
                return ListView.separated(
                  itemCount: detailList.length,
                  separatorBuilder: (_, __) => Divider(),
                  itemBuilder: (context, idx) {
                    final d = detailList[idx];
                    final resultList = d['result'] as List? ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d['status'] ?? "",
                          style: GlobalTextStyles.bodyMedium(isDark: isDark).copyWith(fontWeight: FontWeight.bold),
                        ),
                        ...resultList.map((r) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 7),
                          child: Text(
                            "Time: ${r['time']}, value: ${r['value']}, percentage: ${r['percentage']}%",
                            style: GlobalTextStyles.bodySmall(isDark: isDark),
                          ),
                        )),
                      ],
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
