import 'package:flutter/material.dart';

class PTHDashboardDetailEmpty extends StatelessWidget {
  final bool isDark;
  const PTHDashboardDetailEmpty({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 56, color: isDark ? Colors.white30 : Colors.blue[200]),
          const SizedBox(height: 12),
          Text(
            "Không có dữ liệu chi tiết!",
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black87),
          ),
          const SizedBox(height: 3),
          Text(
            "Hãy thử lọc lại hoặc thay đổi khoảng thời gian.",
            style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black45,
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}
