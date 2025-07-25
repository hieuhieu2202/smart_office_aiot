import 'package:flutter/material.dart';

import 'yield_report_table.dart';

class YieldReportHeaderRow extends StatelessWidget {
  final List dates;
  final bool isDark;
  final ScrollController controller;

  const YieldReportHeaderRow({
    super.key,
    required this.dates,
    required this.isDark,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    Widget cell(String text, {bool alignLeft = false, double? width}) =>
        YieldReportTable.buildCell(
          text,
          isDark,
          header: true,
          alignLeft: alignLeft,
          width: width,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - YieldReportTable.stationWidth;
        double cw = YieldReportTable.cellWidth;
        if (dates.isNotEmpty && dates.length * YieldReportTable.cellWidth < available) {
          cw = available / dates.length;
        }
        final contentWidth = cw * dates.length;
        final canCenter = contentWidth <= available;
        final tableWidth = YieldReportTable.stationWidth + contentWidth;

        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: tableWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                cell('Station', alignLeft: true),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    physics: canCenter ? const NeverScrollableScrollPhysics() : null,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: available),
                      child: Align(
                        alignment: canCenter ? Alignment.center : Alignment.centerLeft,
                        child: Row(
                          children: dates
                              .map<Widget>((d) => cell(d.toString(), width: cw))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
