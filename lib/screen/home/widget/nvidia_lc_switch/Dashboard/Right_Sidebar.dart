import 'package:flutter/material.dart';
import 'Circular_Kpi.dart';
import 'Model_Pass_Tile.dart';

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
        final hasBoundedHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        final panelWidth = constraints.maxWidth.isFinite &&
                constraints.maxWidth > 0
            ? constraints.maxWidth
            : width;
        final isCompactPanel = panelWidth < 340;
        final isMediumPanel = panelWidth < 420;
        final outerPadding = isCompactPanel
            ? const EdgeInsets.all(12)
            : isMediumPanel
                ? const EdgeInsets.all(14)
                : const EdgeInsets.all(16);
        final titleSize = isCompactPanel
            ? 14.0
            : isMediumPanel
                ? 15.0
                : 16.0;
        final sectionSpacing = isCompactPanel ? 12.0 : 14.0;
        final passSpacing = isCompactPanel ? 4.0 : 6.0;
        final circleSize = isCompactPanel
            ? 82.0
            : isMediumPanel
                ? 96.0
                : 116.0;
        final stackKpis = isMobile || isCompactPanel;

        Widget buildPassList(bool scrollable) {
          if (passDetails.isEmpty) {
            final emptyColor = isDark ? Colors.white30 : Colors.black38;
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: sectionSpacing * 1.5),
                child: Text(
                  'No data',
                  style: TextStyle(color: emptyColor, fontSize: titleSize - 2),
                ),
              ),
            );
          }

          return ListView.separated(
            primary: false,
            shrinkWrap: !scrollable,
            physics: scrollable
                ? const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics())
                : const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: passDetails.length,
            separatorBuilder: (_, __) => SizedBox(height: passSpacing),
            itemBuilder: (_, i) {
              final item = passDetails[i];
              return ModelPassTile(
                modelName: item['ModelName'] ?? '',
                qty: item['Qty'] ?? 0,
                maxQty: maxQty,
                colorIndex: i,
                isMobile: isMobile,
              );
            },
          );
        }

        final passList = hasBoundedHeight
            ? Expanded(child: buildPassList(true))
            : buildPassList(false);

        final dividerColor = isDark ? Colors.white12 : Colors.black12;

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
          padding: outerPadding,
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
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: sectionSpacing),

              // === MODEL PASS LIST ===
              passList,
              SizedBox(height: sectionSpacing),

              Divider(height: sectionSpacing + 16, color: dividerColor),

              // === KPI SECTION (WIP + PASS) ===
              Padding(
                padding: EdgeInsets.only(bottom: stackKpis ? 4.0 : 0.0),
                child: stackKpis
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: circleSize,
                            child: CircularKpi(
                              label: "WIP",
                              valueText: "$wip PCS",
                              iconData: Icons.hourglass_bottom,
                            ),
                          ),
                          SizedBox(height: sectionSpacing - 2),
                          SizedBox(
                            width: circleSize,
                            child: CircularKpi(
                              label: "PASS",
                              valueText: "$pass PCS",
                              iconData: Icons.local_shipping,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: circleSize,
                                child: CircularKpi(
                                  label: "WIP",
                                  valueText: "$wip PCS",
                                  iconData: Icons.hourglass_bottom,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: sectionSpacing),
                          Expanded(
                            child: Align(
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: circleSize,
                                child: CircularKpi(
                                  label: "PASS",
                                  valueText: "$pass PCS",
                                  iconData: Icons.local_shipping,
                                ),
                              ),
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
