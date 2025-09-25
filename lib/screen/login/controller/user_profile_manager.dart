// screen/login/controller/user_profile_manager.dart
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:smart_factory/service/auth/auth_config.dart';

class UserProfileManager {
  static final UserProfileManager _instance = UserProfileManager._internal();

  factory UserProfileManager() => _instance;

  UserProfileManager._internal();

  var civetUserno = ''.obs;
  var cnName = ''.obs;
  var vnName = ''.obs; // Thêm thuộc tính mới
  var jobTitle = ''.obs;
  var department = ''.obs;
  var departmentDetail = ''.obs; // Thêm thuộc tính mới
  var location = ''.obs;
  var managers = ''.obs; // Thêm thuộc tính mới
  var hireDate = ''.obs; // Thêm thuộc tính mới
  var avatarUrl = ''.obs; // Thêm thuộc tính mới
  var email = ''.obs; // Thêm thuộc tính mới

  void loadProfile(GetStorage box) {
    civetUserno.value = box.read('civetUserno') ?? '';
    cnName.value = box.read('cnName') ?? '';
    vnName.value = box.read('vnName') ?? '';
    jobTitle.value = box.read('jobTitle') ?? '';
    department.value = box.read('department') ?? '';
    departmentDetail.value = box.read('departmentDetail') ?? '';
    location.value = box.read('location') ?? '';
    managers.value = box.read('managers') ?? '';
    hireDate.value = box.read('hireDate') ?? '';
    avatarUrl.value = _resolveAvatarUrl(box.read('avatarUrl') ?? '');
    email.value = box.read('email') ?? '';
  }

  void updateProfile(
    Map<String, dynamic> decodedToken,
    String username,
    GetStorage box,
  ) {
    civetUserno.value = decodedToken['FoxconnID'] ?? username;
    cnName.value = decodedToken['CN_Name'] ?? '';
    vnName.value = decodedToken['VN_Name'] ?? '';
    jobTitle.value = decodedToken['JobTitle'] ?? '';
    department.value = decodedToken['Department'] ?? '';
    departmentDetail.value = decodedToken['DepartmentDetail'] ?? '';
    location.value = decodedToken['Location'] ?? '';
    managers.value = decodedToken['Managers'] ?? '';
    hireDate.value = decodedToken['HireDate'] ?? '';
    avatarUrl.value =
        _resolveAvatarUrl(decodedToken['AvatarUrl']?.toString() ?? '');
    email.value = decodedToken['Email'] ?? '';

    box.write('civetUserno', civetUserno.value);
    box.write('cnName', cnName.value);
    box.write('vnName', vnName.value);
    box.write('jobTitle', jobTitle.value);
    box.write('department', department.value);
    box.write('departmentDetail', departmentDetail.value);
    box.write('location', location.value);
    box.write('managers', managers.value);
    box.write('hireDate', hireDate.value);
    box.write('avatarUrl', avatarUrl.value);
    box.write('email', email.value);
  }

  void clearProfile(GetStorage box) {
    civetUserno.value = '';
    cnName.value = '';
    vnName.value = '';
    jobTitle.value = '';
    department.value = '';
    departmentDetail.value = '';
    location.value = '';
    managers.value = '';
    hireDate.value = '';
    avatarUrl.value = '';
    email.value = '';
    box.remove('civetUserno');
    box.remove('cnName');
    box.remove('vnName');
    box.remove('jobTitle');
    box.remove('department');
    box.remove('departmentDetail');
    box.remove('location');
    box.remove('managers');
    box.remove('hireDate');
    box.remove('avatarUrl');
    box.remove('email');
  }

  String _resolveAvatarUrl(String url) {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      return '';
    }

    final lowerCaseUrl = trimmedUrl.toLowerCase();
    if (lowerCaseUrl.startsWith('http://') ||
        lowerCaseUrl.startsWith('https://')) {
      return trimmedUrl;
    }

    final base = AuthConfig.baseUrl;
    if (trimmedUrl.startsWith('/')) {
      return '$base$trimmedUrl';
    }

    return '$base/$trimmedUrl';
  }
}
