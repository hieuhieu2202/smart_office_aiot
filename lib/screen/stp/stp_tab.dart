import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/config/global_text_style.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/screen/setting/controller/setting_controller.dart';
import '../../widget/custom_app_bar.dart';
import 'controller/stp_controller.dart';

class SftpScreen extends StatefulWidget {
  const SftpScreen({super.key});

  @override
  State<SftpScreen> createState() => _SftpScreenState();
}

class _SftpScreenState extends State<SftpScreen> {
  final StpController sftpController = Get.put(StpController());
  final SettingController settingController = Get.find<SettingController>();
  final TextEditingController hostController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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

  Future<void> showCreateFolderDialog(bool isDark) async {
    final TextEditingController folderNameController = TextEditingController();
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

  Widget _buildLoginForm(bool isDark) {
    if (sftpController.shouldResetLoginForm.value) {
      hostController.clear();
      usernameController.clear();
      passwordController.clear();
      portController.text =
          sftpController.port.value > 0 ? sftpController.port.value.toString() : '';
      sftpController.shouldResetLoginForm.value = false;
    }

    if (hostController.text.isEmpty && sftpController.host.value.isNotEmpty) {
      hostController.text = sftpController.host.value;
    }
    if (usernameController.text.isEmpty &&
        sftpController.username.value.isNotEmpty) {
      usernameController.text = sftpController.username.value;
    }
    if (passwordController.text.isEmpty &&
        sftpController.password.value.isNotEmpty) {
      passwordController.text = sftpController.password.value;
    }
    if (portController.text.isEmpty && sftpController.port.value > 0) {
      portController.text = sftpController.port.value.toString();
    }

    return Scaffold(
      backgroundColor:
          isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg,
      appBar: CustomAppBar(
        isDark: isDark,
        accent: GlobalColors.accentByIsDark(isDark),
        title: Text(
          'Kết nối WinSCP',
          style: GlobalTextStyles.bodyLarge(isDark: isDark),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nhập thông tin kết nối để truy cập máy chủ.',
              style: GlobalTextStyles.bodyMedium(isDark: isDark),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: hostController,
              label: 'Địa chỉ IP/Host',
              isDark: isDark,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: portController,
              label: 'Cổng (port)',
              isDark: isDark,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: usernameController,
              label: 'Tên đăng nhập',
              isDark: isDark,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: passwordController,
              label: 'Mật khẩu',
              isDark: isDark,
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
            ),
            Obx(
              () => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: sftpController.rememberLogin.value,
                onChanged: (value) async {
                  final isChecked = value ?? false;
                  if (!isChecked && sftpController.hasSavedCredentials.value) {
                    await sftpController.clearRememberedCredentials(
                      resetFormFields: false,
                    );
                  }
                  sftpController.rememberLogin.value = isChecked;
                },
                title: Text(
                  'Lưu thông tin đăng nhập',
                  style: GlobalTextStyles.bodyMedium(isDark: isDark),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: GlobalColors.accentByIsDark(isDark),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final int port = int.tryParse(portController.text.trim()) ?? 0;
                sftpController.connectWithCredentials(
                  host: hostController.text.trim(),
                  port: port,
                  username: usernameController.text.trim(),
                  password: passwordController.text,
                  remember: sftpController.rememberLogin.value,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalColors.accentByIsDark(isDark),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Đăng nhập',
                style: GlobalTextStyles.bodyMedium(isDark: isDark)
                    .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => sftpController.errorMessage.value.isEmpty
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? GlobalColors.cardDarkBg
                                : GlobalColors.cardLightBg)
                            .withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sftpController.errorMessage.value,
                        style: GlobalTextStyles.bodyMedium(isDark: isDark).copyWith(
                          color: GlobalColors.accentByIsDark(isDark),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Obx(
              () {
                final shouldShowClear = sftpController.rememberLogin.value ||
                    sftpController.hasSavedCredentials.value;
                if (!shouldShowClear) {
                  return const SizedBox.shrink();
                }
                return OutlinedButton(
                  onPressed: () async {
                    await sftpController.clearRememberedCredentials();
                    hostController.clear();
                    portController.clear();
                    usernameController.clear();
                    passwordController.clear();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Xóa thông tin đã lưu',
                    style: GlobalTextStyles.bodyMedium(isDark: isDark),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GlobalTextStyles.bodyMedium(isDark: isDark),
        filled: true,
        fillColor: isDark
            ? GlobalColors.inputDarkFill.withOpacity(0.16)
            : GlobalColors.inputLightFill.withOpacity(0.18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      style: GlobalTextStyles.bodyMedium(isDark: isDark),
    );
  }

  @override
  void dispose() {
    hostController.dispose();
    portController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isDark = settingController.isDarkMode.value;

      if (!sftpController.isConnected.value) {
        return _buildLoginForm(isDark);
      }

      final bool isRoot = sftpController.currentPath.value == '/';

      return Scaffold(
        backgroundColor: isDark
            ? GlobalColors.bodyDarkBg
            : GlobalColors.bodyLightBg,
        appBar: CustomAppBar(
          isDark: isDark,
          accent: GlobalColors.accentByIsDark(isDark),

          // Leading: chỉ hiện nút back nếu KHÔNG ở root
          leading: isRoot
              ? null
              : IconButton(
            icon: Icon(Icons.arrow_back,
                color: isDark
                    ? GlobalColors.darkPrimaryText
                    : GlobalColors.lightPrimaryText),
            onPressed: () {
              sftpController.goBack();
            },
          ),
          // Title: Breadcrumb
          title: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _buildBreadcrumb(sftpController, isDark)),
          ),
          actions: [
            IconButton(
              onPressed: () async => await sftpController.logout(),
              icon: Icon(
                Icons.logout,
                color: isDark
                    ? GlobalColors.darkPrimaryText
                    : GlobalColors.lightPrimaryText,
              ),
              tooltip: 'Đăng xuất',
            ),
            PopupMenuButton<String>(
              color: isDark
                  ? GlobalColors.cardDarkBg
                  : GlobalColors.cardLightBg,
              onSelected: (value) {
                if (value == 'createFolder') {
                  showCreateFolderDialog(isDark);
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
          heroTag: 'stp-refresh-fab',
          backgroundColor: isDark
              ? GlobalColors.primaryButtonDark
              : GlobalColors.primaryButtonLight,
          onPressed: () =>
              sftpController.listDirectory(sftpController.currentPath.value),
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
      );
    });
  }
}
