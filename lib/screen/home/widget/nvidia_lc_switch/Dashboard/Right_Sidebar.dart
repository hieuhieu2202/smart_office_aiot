import 'package:flutter/material.dart';
import 'circular_kpi.dart';
import 'model_pass_tile.dart';

class RightSidebar extends StatelessWidget {
  final List<Map<String, dynamic>> passDetails;
  final int wip;
  final int pass;

  const RightSidebar({
    super.key,
    required this.passDetails,
    required this.wip,
    required this.pass,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderClr = isDark ? Colors.cyanAccent : Colors.blueAccent;
    final bgColor = isDark
        ? const Color(0xFF061B28)
        : const Color(0xFFF9FCFE).withOpacity(0.95);

    // ✅ Responsive
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    // === Tìm giá trị lớn nhất trong Model Pass ===
    int maxQty = 1;
    for (var i in passDetails) {
      final q = (i['Qty'] ?? 0) as int;
      if (q > maxQty) maxQty = q;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite;

        Widget buildPassList() {
          return SingleChildScrollView(
            child: Column(
              children: [
                ...List.generate(passDetails.length, (i) {
                  final item = passDetails[i];
                  return ModelPassTile(
                    modelName: item['ModelName'] ?? '',
                    qty: item['Qty'] ?? 0,
                    maxQty: maxQty,
                    colorIndex: i,
                    isMobile: isMobile,
                  );
                }),
              ],
            ),
          );
        }

        final passList = hasBoundedHeight
            ? Expanded(child: buildPassList())
            : Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: buildPassList(),
              );

        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderClr.withOpacity(.25)),
            boxShadow: [
              BoxShadow(
                  color: borderClr.withOpacity(.15),
                  blurRadius: 20,
                  spreadRadius: 2)
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize:
                hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === TITLE ===
              Text(
                "MODEL PASS",
                style: TextStyle(
                  color: borderClr,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 14),

              // === MODEL PASS LIST ===
              passList,

              const Divider(height: 28, color: Colors.white12),

              // === KPI SECTION (WIP + PASS) ===
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: isMobile
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularKpi(
                            label: "WIP",
                            valueText: "$wip PCS",
                            iconData: Icons.hourglass_bottom,
                          ),
                          const SizedBox(height: 12),
                          CircularKpi(
                            label: "PASS",
                            valueText: "$pass PCS",
                            iconData: Icons.local_shipping,
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Flexible(
                            flex: 1,
                            child: CircularKpi(
                              label: "WIP",
                              valueText: "$wip PCS",
                              iconData: Icons.hourglass_bottom,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            flex: 1,
                            child: CircularKpi(
                              label: "PASS",
                              valueText: "$pass PCS",
                              iconData: Icons.local_shipping,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
