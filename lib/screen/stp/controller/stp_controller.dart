import 'dart:io';
import 'package:get/get.dart';
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
  SftpClient? sftpClient;
  SSHClient? sshClient;

  final String host = '10.220.130.115';
  final String username = 'Automation';
  final String password = 'auto123';
  final int port = 6742;

  @override
  void onInit() {
    super.onInit();
    _checkAndConnect();
  }

  Future<void> _checkAndConnect() async {
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
      print('Đang kết nối $host:$port...');
      final socket = await SSHSocket.connect(host, port);
      sshClient = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
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
