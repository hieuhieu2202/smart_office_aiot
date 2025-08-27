import 'package:flutter/material.dart';
import '../../controller/te_management_controller.dart';

class TEManagementSearchBar extends StatelessWidget {
  final TEManagementController controller;
  final bool isDark;
  const TEManagementSearchBar({
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
                hintText: 'Search model, group, value...',
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
