import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../../config/global_color.dart';
import '../../../service/aoivi_dashboard_api.dart';
import 'avi_dashboard_detail_row.dart';
import 'avi_dashboard_image_grid_dialog.dart';
import 'avi_dashboard_status_chip.dart';

class PTHDashboardDetailCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const PTHDashboardDetailCard({super.key, required this.item});

  // Hàm mở popup grid ảnh
  Future<void> _showImages(BuildContext context) async {
    final int? id = item['id'] is int ? item['id'] : int.tryParse(item['id']?.toString() ?? '');
    if (id == null) {
      Get.snackbar("Lỗi", "Không lấy được ID hợp lệ!");
      return;
    }

    // Gọi API lấy chi tiết theo ID
    final detail = await PTHDashboardApi.getMonitoringDataById(id);
    if (detail == null) {
      Get.snackbar("Lỗi", "Không lấy được dữ liệu ảnh!");
      return;
    }

    final String imageDetailsJson = detail['imageDetails'] ?? '';
    if (imageDetailsJson.isEmpty || imageDetailsJson.toUpperCase() == 'N/A') {
      Get.snackbar("Không có ảnh", "Bản ghi không có danh sách ảnh.");
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => PTHDashboardImageGridDialog(
        serialNumber: detail['serialNumber'] ?? '',
        imageDetailsJson: imageDetailsJson,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = (item['status'] ?? '').toString().toUpperCase();
    final isFail = status == 'FAIL';
    final statusColor = isFail ? Colors.red : Colors.green;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showImages(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isDark
              ? const LinearGradient(
            colors: [Color(0xFF26314D), Color(0xFF2B447A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : const LinearGradient(
            colors: [Color(0xFFe3f0fa), Color(0xFFb6d0ea)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.13)
                  : Colors.blueGrey.withOpacity(0.09),
              blurRadius: 13,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: isDark
                ? GlobalColors.borderDark
                : GlobalColors.borderLight,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            // Icon/Barcode
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFail
                    ? Colors.red.withOpacity(0.07)
                    : Colors.green.withOpacity(0.09),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.qr_code_2, size: 26, color: statusColor),
            ),
            const SizedBox(width: 13),
            // Info Grid
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SN + Status Chip
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['serialNumber'] ?? "--",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: isDark
                                ? GlobalColors.primaryButtonDark
                                : GlobalColors.primaryButtonLight,
                            letterSpacing: .2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      PTHDashboardStatusChip(text: status, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 14,
                    runSpacing: 3,
                    children: [
                      PTHDashboardDetailRow(
                        icon: Icons.memory,
                        label: "Model:",
                        value: item['modelName'] ?? "--",
                        color: Colors.teal[600],
                      ),
                      PTHDashboardDetailRow(
                        icon: Icons.person,
                        label: "Nhân viên:",
                        value: item['employeeID'] ?? "--",
                        color: Colors.deepPurple[400],
                      ),
                      PTHDashboardDetailRow(
                        icon: Icons.timer_outlined,
                        label: "Cycle:",
                        value: item['cycleTime']?.toString() ?? "--",
                        color: Colors.orange[700],
                      ),
                      PTHDashboardDetailRow(
                        icon: Icons.access_time,
                        label: "Thời gian:",
                        value: item['inspectionTime'] != null
                            ? DateFormat('yyyy/MM/dd HH:mm:ss').format(
                            DateTime.tryParse(item['inspectionTime']) ??
                                DateTime(2000))
                            : "--",
                        color: Colors.blue[600],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
