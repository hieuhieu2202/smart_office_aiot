import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/screen/home/controller/clean_room_controller.dart';
import 'dashboard_card.dart';

class LocationInfoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CleanRoomController controller = Get.find<CleanRoomController>();

    return Obx(
      () => DashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin vị trí',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _buildItem('Khách hàng', controller.selectedCustomer.value),
                _buildItem('Nhà máy', controller.selectedFactory.value),
                _buildItem('Tầng', controller.selectedFloor.value),
                _buildItem('Phòng', controller.selectedRoom.value),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(value.isEmpty ? 'Chưa chọn' : value),
      ],
    );
  }
}
