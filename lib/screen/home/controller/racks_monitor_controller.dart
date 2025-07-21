import 'package:get/get.dart';
import '../../../service/lc_switch_rack_api.dart';

class RacksMonitorController extends GetxController {
  var racks = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadRacks();
  }

  Future<void> loadRacks() async {
    try {
      isLoading.value = true;
      error.value = '';
      final data = await LCSwitchRackApi.getRackMonitoring();
      final list = data['Data']?['RackDetails'];
      if (list is List) {
        racks.value = List<Map<String, dynamic>>.from(list);
      } else {
        racks.value = [];
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
