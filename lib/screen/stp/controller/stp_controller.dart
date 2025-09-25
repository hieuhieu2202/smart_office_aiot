import 'dart:io';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class StpController extends GetxController {
  var isConnected = false.obs;
  var currentPath = '/'.obs;
  var filesAndFolders = <String, bool>{}.obs;
  var errorMessage = ''.obs;
  var rememberLogin = false.obs;
  var allowAutoLogin = false.obs;
  var hasSavedCredentials = false.obs;
  var host = ''.obs;
  var username = ''.obs;
  var password = ''.obs;
  var port = 6742.obs;
  var shouldResetLoginForm = false.obs;

  final GetStorage _box = GetStorage();
  SftpClient? sftpClient;
  SSHClient? sshClient;

  @override
  void onInit() {
    super.onInit();
    _loadSavedCredentials();
    if (allowAutoLogin.value &&
        rememberLogin.value &&
        host.value.isNotEmpty &&
        username.value.isNotEmpty &&
        password.value.isNotEmpty) {
      _checkAndConnect();
    }
  }

  void _loadSavedCredentials() {
    final savedHost = _box.read('sftpHost') ?? '';
    final savedUsername = _box.read('sftpUsername') ?? '';
    final savedPassword = _box.read('sftpPassword') ?? '';
    final savedPort = _box.read('sftpPort') ?? 6742;
    final savedRemember = _box.read('sftpRemember') ?? false;
    final savedAutoLogin = _box.read('sftpAutoLogin') ?? false;

    host.value = savedHost;
    username.value = savedUsername;
    password.value = savedPassword;
    port.value = savedPort;
    rememberLogin.value = savedRemember;

    hasSavedCredentials.value =
        savedRemember &&
        savedHost.isNotEmpty &&
        savedUsername.isNotEmpty &&
        savedPassword.isNotEmpty;

    allowAutoLogin.value = hasSavedCredentials.value && savedAutoLogin;
    if (!hasSavedCredentials.value) {
      allowAutoLogin.value = false;
      host.value = '';
      username.value = '';
      password.value = '';
      port.value = 6742;
      rememberLogin.value = false;
      _box.write('sftpAutoLogin', false);
      _box.write('sftpRemember', false);
      _box.remove('sftpHost');
      _box.remove('sftpUsername');
      _box.remove('sftpPassword');
      _box.remove('sftpPort');
    }
    shouldResetLoginForm.value = false;
  }

  Future<void> _checkAndConnect() async {
    if (host.value.isEmpty ||
        username.value.isEmpty ||
        password.value.isEmpty ||
        port.value <= 0) {
      isConnected.value = false;
      errorMessage.value = 'Thiếu thông tin đăng nhập!';
      return;
    }

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      isConnected.value = false;
      errorMessage.value = 'Không có kết nối mạng!';
      Get.snackbar(
        'Lỗi',
        'Không có kết nối mạng!',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText:
            Get.isDarkMode
                ? GlobalColors.darkPrimaryText
                : GlobalColors.lightPrimaryText,
      );
    } else {
      await connectToSftp();
    }
  }

  Future<void> connectToSftp() async {
    try {
      print('Đang kết nối ${host.value}:${port.value}...');
      final socket = await SSHSocket.connect(host.value, port.value);
      sshClient = SSHClient(
        socket,
        username: username.value,
        onPasswordRequest: () => password.value,
      );
      sftpClient = await sshClient!.sftp();
      isConnected.value = true;
      errorMessage.value = '';
      await listDirectory(currentPath.value);
      Get.snackbar(
        'Thành công',
        'Kết nối đến Sever thành công!',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText:
            Get.isDarkMode
                ? GlobalColors.darkPrimaryText
                : GlobalColors.lightPrimaryText,
      );
    } catch (e) {
      isConnected.value = false;
      errorMessage.value = 'Kết nối thất bại: $e';
      print('Lỗi kết nối: $e');
      Get.snackbar(
        'Lỗi',
        'Kết nối thất bại: $e',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText:
            Get.isDarkMode
                ? GlobalColors.darkPrimaryText
                : GlobalColors.lightPrimaryText,
      );
    }
  }

  Future<void> connectWithCredentials({
    required String host,
    required int port,
    required String username,
    required String password,
    required bool remember,
  }) async {
    if (host.trim().isEmpty ||
        username.trim().isEmpty ||
        password.isEmpty ||
        port <= 0) {
      errorMessage.value = 'Vui lòng nhập đầy đủ thông tin hợp lệ!';
      Get.snackbar(
        'Lỗi',
        'Vui lòng nhập đầy đủ thông tin hợp lệ!',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText: Get.isDarkMode
            ? GlobalColors.darkPrimaryText
            : GlobalColors.lightPrimaryText,
      );
      return;
    }

    this.host.value = host.trim();
    this.username.value = username.trim();
    this.password.value = password;
    this.port.value = port;
    rememberLogin.value = remember;
    shouldResetLoginForm.value = false;

    allowAutoLogin.value = remember;
    hasSavedCredentials.value = remember;

    if (remember) {
      _box.write('sftpHost', this.host.value);
      _box.write('sftpUsername', this.username.value);
      _box.write('sftpPassword', this.password.value);
      _box.write('sftpPort', this.port.value);
      _box.write('sftpRemember', true);
      _box.write('sftpAutoLogin', true);
    } else {
      _box.remove('sftpHost');
      _box.remove('sftpUsername');
      _box.remove('sftpPassword');
      _box.remove('sftpPort');
      _box.write('sftpRemember', false);
      _box.write('sftpAutoLogin', false);
      hasSavedCredentials.value = false;
    }

    await _checkAndConnect();
  }

  void clearRememberedCredentials({bool resetFormFields = true}) {
    allowAutoLogin.value = false;
    rememberLogin.value = false;
    hasSavedCredentials.value = false;
    _box.write('sftpAutoLogin', false);
    _box.write('sftpRemember', false);
    _box.remove('sftpHost');
    _box.remove('sftpUsername');
    _box.remove('sftpPassword');
    _box.remove('sftpPort');

    if (resetFormFields) {
      host.value = '';
      username.value = '';
      password.value = '';
      port.value = 6742;
      shouldResetLoginForm.value = true;
    }
  }

  Future<void> logout() async {
    final currentSftpClient = sftpClient;
    if (currentSftpClient != null) {
      currentSftpClient.close();
    }

    final currentSshClient = sshClient;
    if (currentSshClient != null) {
      currentSshClient.close();
    }
    sftpClient = null;
    sshClient = null;
    isConnected.value = false;
    filesAndFolders.clear();
    currentPath.value = '/';
    errorMessage.value = '';

    clearRememberedCredentials();

    Get.snackbar(
      'Đăng xuất',
      'Đã ngắt kết nối khỏi máy chủ WinSCP.',
      snackStyle: SnackStyle.FLOATING,
      backgroundColor:
          Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
      colorText:
          Get.isDarkMode ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText,
    );
  }

  Future<void> listDirectory(String path) async {
    if (!isConnected.value || sftpClient == null) {
      // Thử kết nối lại nếu mất kết nối
      await _checkAndConnect();
      if (!isConnected.value || sftpClient == null) {
        errorMessage.value = 'Không thể kết nối để liệt kê thư mục!';
        Get.snackbar(
          'Lỗi',
          'Không thể kết nối để liệt kê thư mục!',
          snackStyle: SnackStyle.FLOATING,
          backgroundColor:
              Get.isDarkMode
                  ? GlobalColors.cardDarkBg
                  : GlobalColors.cardLightBg,
          colorText:
              Get.isDarkMode
                  ? GlobalColors.darkPrimaryText
                  : GlobalColors.lightPrimaryText,
        );
        return;
      }
    }

    try {
      filesAndFolders.clear();
      await for (var items in sftpClient!.readdir(path)) {
        for (var item in items) {
          final isDir = item.attr.isDirectory;
          filesAndFolders[item.filename] = isDir;
        }
      }
      currentPath.value = path;
      errorMessage.value = '';
      Get.snackbar(
        'Thành công',
        'Danh sách thư mục đã được cập nhật!',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText:
            Get.isDarkMode
                ? GlobalColors.darkPrimaryText
                : GlobalColors.lightPrimaryText,
      );
    } catch (e) {
      if ((!isConnected.value || sftpClient == null) &&
          e.toString().contains('Connection closed')) {
        return;
      }
      errorMessage.value = 'Lỗi khi liệt kê thư mục: $e';
      print('Lỗi liệt kê: $e');
      Get.snackbar(
        'Lỗi',
        'Lỗi khi liệt kê thư mục: $e',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText:
            Get.isDarkMode
                ? GlobalColors.darkPrimaryText
                : GlobalColors.lightPrimaryText,
      );
    }
  }

  Future<void> navigateTo(String folderName) async {
    String newPath =
        currentPath.value == '/'
            ? '/$folderName'
            : '${currentPath.value}/$folderName';
    await listDirectory(newPath);
  }

  Future<void> goBack() async {
    if (currentPath.value == '/') return;
    String parentPath = currentPath.value.substring(
      0,
      currentPath.value.lastIndexOf('/'),
    );
    if (parentPath.isEmpty) parentPath = '/';
    await listDirectory(parentPath);
  }

  Future<void> downloadFile(String filename) async {
    if (!isConnected.value || sftpClient == null) {
      errorMessage.value = 'Chưa kết nối đến Sever!';
      Get.snackbar(
        'Lỗi',
        'Chưa kết nối đến Sever!',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText:
            Get.isDarkMode
                ? GlobalColors.darkPrimaryText
                : GlobalColors.lightPrimaryText,
      );
      return;
    }

    try {
      var storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted) {
        errorMessage.value = 'Không có quyền lưu dữ liệu!';
        Get.snackbar(
          'Lỗi',
          'Không có quyền lưu trữ!',
          snackStyle: SnackStyle.FLOATING,
          backgroundColor:
              Get.isDarkMode
                  ? GlobalColors.cardDarkBg
                  : GlobalColors.cardLightBg,
          colorText:
              Get.isDarkMode
                  ? GlobalColors.darkPrimaryText
                  : GlobalColors.lightPrimaryText,
        );
        return;
      }
      final remotePath =
          currentPath.value == '/'
              ? '/$filename'
              : '${currentPath.value}/$filename';
      final fileHandle = await sftpClient!.open(
        remotePath,
        mode: SftpFileOpenMode.read,
      );
      final content = await fileHandle.readBytes();
      await fileHandle.close();
      final localDir = await getExternalStorageDirectory();
      final localPath = '${localDir!.path}/$filename';
      final localFile = File(localPath);
      await localFile.writeAsBytes(content);

      errorMessage.value = 'Tải ảnh thành công: $localPath';
      Get.snackbar(
        'Thành công',
        'Đã tải file về: $localPath',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText:
            Get.isDarkMode
                ? GlobalColors.darkPrimaryText
                : GlobalColors.lightPrimaryText,
      );
    } catch (e) {
      errorMessage.value = 'Lỗi khi tải file: $e';
      print('Lỗi tải file: $e');
      Get.snackbar(
        'Lỗi',
        'Tải file thất bại: $e',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText:
            Get.isDarkMode
                ? GlobalColors.darkPrimaryText
                : GlobalColors.lightPrimaryText,
      );
    }
  }

  Future<void> uploadFile(String localPath, String filename) async {
    if (!isConnected.value || sftpClient == null) {
      errorMessage.value = 'Chưa kết nối đến Sever!';
      Get.snackbar(
        'Lỗi',
        'Chưa kết nối đến server!',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText:
            Get.isDarkMode
                ? GlobalColors.darkPrimaryText
                : GlobalColors.lightPrimaryText,
      );
      return;
    }
    try {
      final remotePath =
          currentPath.value == '/'
              ? '/$filename'
              : '${currentPath.value}/$filename';

      final localFile = File(localPath);
      final content = await localFile.readAsBytes();

      final fileHandle = await sftpClient!.open(
        remotePath,
        mode:
            SftpFileOpenMode.write |
            SftpFileOpenMode.create |
            SftpFileOpenMode.truncate,
      );
      await fileHandle.writeBytes(content);
      await fileHandle.close();

      await listDirectory(currentPath.value);
      errorMessage.value = 'Upload file thành công: $remotePath';
      Get.snackbar(
        'Thành công',
        'Đã upload file lên: $remotePath',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText:
            Get.isDarkMode
                ? GlobalColors.darkPrimaryText
                : GlobalColors.lightPrimaryText,
      );
    } catch (e) {
      errorMessage.value = 'Lỗi khi upload file: $e';
      print('Lỗi upload file: $e');
      Get.snackbar(
        'Lỗi',
        'Upload file thất bại: $e',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText:
            Get.isDarkMode
                ? GlobalColors.darkPrimaryText
                : GlobalColors.lightPrimaryText,
      );
    }
  }

  Future<void> deleteFile(String filename) async {
    if (!isConnected.value || sftpClient == null) {
      errorMessage.value = 'Chưa kết nối đến server!';
      Get.snackbar(
        'Lỗi',
        'Chưa kết nối đến server!',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText:
            Get.isDarkMode
                ? GlobalColors.darkPrimaryText
                : GlobalColors.lightPrimaryText,
      );
      return;
    }

    try {
      final remotePath =
          currentPath.value == '/'
              ? '/$filename'
              : '${currentPath.value}/$filename';

      await sftpClient!.remove(remotePath);

      await listDirectory(currentPath.value);
      errorMessage.value = 'Xóa file thành công: $remotePath';
      Get.snackbar(
        'Thành công',
        'Đã xóa file: $remotePath',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText:
            Get.isDarkMode
                ? GlobalColors.darkPrimaryText
                : GlobalColors.lightPrimaryText,
      );
    } catch (e) {
      errorMessage.value = 'Lỗi khi xóa file: $e';
      print('Lỗi xóa file: $e');
      Get.snackbar(
        'Lỗi',
        'Xóa file thất bại: $e',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText:
            Get.isDarkMode
                ? GlobalColors.darkPrimaryText
                : GlobalColors.lightPrimaryText,
      );
    }
  }

  Future<void> createDirectory(String folderName) async {
    if (!isConnected.value || sftpClient == null) {
      errorMessage.value = 'Chưa kết nối đến server!';
      Get.snackbar(
        'Lỗi',
        'Chưa kết nối đến server!',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText:
            Get.isDarkMode
                ? GlobalColors.darkPrimaryText
                : GlobalColors.lightPrimaryText,
      );
      return;
    }

    try {
      final newPath =
          currentPath.value == '/'
              ? '/$folderName'
              : '${currentPath.value}/$folderName';
      await sftpClient!.mkdir(newPath);
      await listDirectory(currentPath.value);
      errorMessage.value = 'Tạo thư mục thành công: $newPath';
      Get.snackbar(
        'Thành công',
        'Đã tạo thư mục: $newPath',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText:
            Get.isDarkMode
                ? GlobalColors.darkPrimaryText
                : GlobalColors.lightPrimaryText,
      );
    } catch (e) {
      errorMessage.value = 'Lỗi khi tạo thư mục: $e';
      print('Lỗi tạo thư mục: $e');
      Get.snackbar(
        'Lỗi',
        'Tạo thư mục thất bại: $e',
        snackStyle: SnackStyle.FLOATING,
        backgroundColor:
            Get.isDarkMode ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        colorText:
            Get.isDarkMode
                ? GlobalColors.darkPrimaryText
                : GlobalColors.lightPrimaryText,
      );
    }
  }

  @override
  void onClose() {
    sftpClient?.close();
    sshClient?.close();
    isConnected.value = false;
    super.onClose();
  }
}
