import 'package:get/get.dart';
import '../../../model/notification_message.dart';
import '../../../service/notification_service.dart';

class NotificationController extends GetxController {
  var notifications = <NotificationMessage>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      final data = await NotificationService.getNotifications();
      notifications.assignAll(data);
    } finally {
      isLoading.value = false;
    }
  }
}
