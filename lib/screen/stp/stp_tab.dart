import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/config/global_text_style.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/screen/setting/controller/setting_controller.dart';
import 'controller/stp_controller.dart';

class SftpScreen extends StatelessWidget {
  final StpController sftpController = Get.put(StpController());
  final SettingController settingController = Get.find<SettingController>();

  Future<void> pickFileAndUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      String? localPath = result.files.single.path;
      String filename = result.files.single.name;
      if (localPath != null) {
        await sftpController.uploadFile(localPath, filename);
      }
    }
  }

  Future<void> showCreateFolderDialog() async {
    final TextEditingController folderNameController = TextEditingController();
    final bool isDark = settingController.isDarkMode.value;
    Get.dialog(
      AlertDialog(
        backgroundColor: isDark
            ? GlobalColors.cardDarkBg
            : GlobalColors.cardLightBg,
        title: Text('Tạo thư mục mới',
            style: GlobalTextStyles.bodyLarge(isDark: isDark)),
        content: TextField(
          controller: folderNameController,
          decoration: InputDecoration(
            labelText: 'Tên thư mục',
            labelStyle: GlobalTextStyles.bodyMedium(isDark: isDark),
            filled: true,
            fillColor: isDark
                ? GlobalColors.inputDarkFill.withOpacity(0.16)
                : GlobalColors.inputLightFill.withOpacity(0.18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          style: GlobalTextStyles.bodyMedium(isDark: isDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Hủy', style: GlobalTextStyles.bodyMedium(isDark: isDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? GlobalColors.primaryButtonDark
                  : GlobalColors.primaryButtonLight,
            ),
            onPressed: () {
              if (folderNameController.text.isNotEmpty) {
                sftpController.createDirectory(folderNameController.text);
                Get.back();
              }
            },
            child: Text(
              'Tạo',
              style: GlobalTextStyles.bodyMedium(isDark: isDark).copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Xác định icon dựa trên tên file
  IconData _getFileIcon(String filename) {
    String extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'txt':
        return Icons.text_snippet;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_library;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Breadcrumb AppBar
  List<Widget> _buildBreadcrumb(StpController controller, bool isDark) {
    List<String> pathSegments =
    controller.currentPath.value.split('/').where((segment) => segment.isNotEmpty).toList();
    List<Widget> breadcrumbs = [
      InkWell(
        onTap: () => controller.listDirectory('/'),
        child: Text(
          'Root',
          style: GlobalTextStyles.bodyMedium(isDark: isDark).copyWith(
            color: isDark ? GlobalColors.primaryButtonDark : GlobalColors.primaryButtonLight,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];

    String currentPath = '';
    for (int i = 0; i < pathSegments.length; i++) {
      currentPath += '/${pathSegments[i]}';
      final pathToNavigate = currentPath;
      breadcrumbs.add(const Text(' > '));
      breadcrumbs.add(
        InkWell(
          onTap: () => controller.listDirectory(pathToNavigate),
          child: Text(
            pathSegments[i],
            style: GlobalTextStyles.bodyMedium(isDark: isDark).copyWith(
              color: i == pathSegments.length - 1
                  ? (isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText)
                  : (isDark ? GlobalColors.primaryButtonDark : GlobalColors.primaryButtonLight),
              fontWeight: i == pathSegments.length - 1 ? FontWeight.normal : FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return breadcrumbs;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = settingController.isDarkMode.value;

    return Scaffold(
      backgroundColor: isDark
          ? GlobalColors.bodyDarkBg
          : GlobalColors.bodyLightBg,
      appBar: AppBar(
        backgroundColor: isDark
            ? GlobalColors.appBarDarkBg
            : GlobalColors.appBarLightBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark
                  ? GlobalColors.darkPrimaryText
                  : GlobalColors.lightPrimaryText),
          onPressed: () {
            if (sftpController.currentPath.value != '/') {
              sftpController.goBack();
            } else {
              Get.back();
            }
          },
        ),
        title: Obx(
              () => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _buildBreadcrumb(sftpController, isDark)),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            color: isDark
                ? GlobalColors.cardDarkBg
                : GlobalColors.cardLightBg,
            onSelected: (value) {
              if (value == 'createFolder') {
                showCreateFolderDialog();
              } else if (value == 'uploadFile') {
                pickFileAndUpload();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'createFolder',
                child: Text(
                  'Tạo thư mục',
                  style: GlobalTextStyles.bodyMedium(isDark: isDark),
                ),
              ),
              PopupMenuItem(
                value: 'uploadFile',
                child: Text(
                  'Thêm file',
                  style: GlobalTextStyles.bodyMedium(isDark: isDark),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (!sftpController.isConnected.value) {
          return Center(
            child: Text(
              'Đang kết nối... ${sftpController.errorMessage.value}',
              style: GlobalTextStyles.bodyMedium(isDark: isDark),
            ),
          );
        }

        if (sftpController.filesAndFolders.isEmpty) {
          return Center(
            child: Text('Thư mục trống', style: GlobalTextStyles.bodyMedium(isDark: isDark)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: sftpController.filesAndFolders.length,
          itemBuilder: (context, index) {
            final itemName = sftpController.filesAndFolders.keys.elementAt(index);
            final isFolder = sftpController.filesAndFolders[itemName] ?? false;

            return Card(
              elevation: 2,
              color: isDark
                  ? GlobalColors.cardDarkBg
                  : GlobalColors.cardLightBg,
              child: ListTile(
                leading: Icon(
                  isFolder ? Icons.folder : _getFileIcon(itemName),
                  color: isFolder
                      ? (isDark
                      ? GlobalColors.primaryButtonDark
                      : GlobalColors.primaryButtonLight)
                      : (_getFileIcon(itemName) == Icons.image
                      ? Colors.green
                      : (isDark
                      ? GlobalColors.primaryButtonDark
                      : GlobalColors.primaryButtonLight)),
                ),
                title: Text(itemName, style: GlobalTextStyles.bodyMedium(isDark: isDark)),
                trailing: !isFolder
                    ? PopupMenuButton<String>(
                  color: isDark
                      ? GlobalColors.cardDarkBg
                      : GlobalColors.cardLightBg,
                  onSelected: (value) {
                    if (value == 'download') {
                      sftpController.downloadFile(itemName);
                    } else if (value == 'delete') {
                      sftpController.deleteFile(itemName);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'download',
                      child: Text(
                        'Tải xuống',
                        style: GlobalTextStyles.bodyMedium(isDark: isDark),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Xóa',
                        style: GlobalTextStyles.bodyMedium(isDark: isDark),
                      ),
                    ),
                  ],
                )
                    : null,
                onTap: isFolder
                    ? () => sftpController.navigateTo(itemName)
                    : () => Get.snackbar(
                  'Thông tin',
                  'Đây là tệp: $itemName',
                  snackStyle: SnackStyle.FLOATING,
                  backgroundColor: isDark
                      ? GlobalColors.cardDarkBg
                      : GlobalColors.cardLightBg,
                  colorText: isDark
                      ? GlobalColors.darkPrimaryText
                      : GlobalColors.lightPrimaryText,
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDark
            ? GlobalColors.primaryButtonDark
            : GlobalColors.primaryButtonLight,
        onPressed: () =>
            sftpController.listDirectory(sftpController.currentPath.value),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
