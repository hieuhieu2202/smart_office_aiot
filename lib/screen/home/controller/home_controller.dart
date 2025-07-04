import 'package:get/get.dart';
import 'package:smart_factory/data/app_data.dart';
import 'package:smart_factory/model/AppModel.dart';
import '../../login/controller/login_controller.dart';

class HomeController extends GetxController {
  var userName = ''.obs;
  var activePanel = 0.obs; // 0: Project, 1: Chat, 2: Notification
  var isLoading = false.obs;
  var responseMessage = ''.obs;
  final loginController = Get.find<LoginController>();
  var projects = <AppProject>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadProjects(); // Load dữ liệu khi khởi tạo
    userName.value = loginController.username.value;
  }

  // Phương thức tải hoặc reload dữ liệu dự án
  Future<void> loadProjects() async {
    try {
      isLoading.value = true;
      responseMessage.value = '';
      projects.assignAll(appProjects); // Gán danh sách dự án từ app_data.dart
    } catch (e) {
      responseMessage.value = 'Lỗi khi tải dự án: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Đặt panel hoạt động
  void setActivePanel(int index) {
    activePanel.value = index;
  }

  // Đăng xuất
  void logout() {
    loginController.logout();
  }

  // (Tùy chọn) Phương thức để lấy dự án con nếu cần
  List<AppProject> getSubProjects(AppProject project) {
    return project.subProjects;
  }
}