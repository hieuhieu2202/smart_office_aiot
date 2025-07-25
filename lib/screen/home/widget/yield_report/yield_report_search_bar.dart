import 'package:flutter/material.dart';

import '../../controller/yield_report_controller.dart';

class YieldReportSearchBar extends StatelessWidget {
  final YieldReportController controller;
  final bool isDark;

  const YieldReportSearchBar({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(13, 18, 13, 0),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF37474F) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.10) : Colors.grey.withOpacity(0.13),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: isDark ? Colors.white54 : Colors.grey[700],
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
              decoration: const InputDecoration(
                hintText: 'T\u00ecm ki\u1ebfm NickName, Model, Station...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontWeight: FontWeight.w400),
              ),
              onChanged: controller.updateQuickFilter,
            ),
          ),
        ],
      ),
    );
  }
}
