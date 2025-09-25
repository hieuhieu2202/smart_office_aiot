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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  decoration: BoxDecoration(
                    color: (isDark
                            ? GlobalColors.cardDarkBg.withOpacity(0.92)
                            : GlobalColors.cardLightBg)
                        .withOpacity(isDark ? 0.92 : 0.98),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? GlobalColors.borderDark.withOpacity(0.6)
                          : GlobalColors.borderLight.withOpacity(0.65),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark
                                ? GlobalColors.shadowDark
                                : GlobalColors.shadowLight)
                            .withOpacity(isDark ? 0.35 : 0.45),
                        blurRadius: 24,
                        spreadRadius: -8,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_sync_rounded,
                            size: 32,
                            color: GlobalColors.accentByIsDark(isDark),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Thông tin đăng nhập',
                            style: GlobalTextStyles.bodyLarge(isDark: isDark)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nhập thông tin kết nối để truy cập máy chủ.',
                        textAlign: TextAlign.center,
                        style: GlobalTextStyles.bodyMedium(isDark: isDark)
                            .copyWith(
                          color: isDark
                              ? GlobalColors.darkSecondaryText
                              : GlobalColors.lightSecondaryText,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: hostController,
                        label: 'Địa chỉ IP/Host',
                        isDark: isDark,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: portController,
                        label: 'Cổng (port)',
                        isDark: isDark,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: usernameController,
                        label: 'Tên đăng nhập',
                        isDark: isDark,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: passwordController,
                        label: 'Mật khẩu',
                        isDark: isDark,
                        obscureText: true,
                        keyboardType: TextInputType.visiblePassword,
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () => CheckboxListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          tileColor: (isDark
                                  ? GlobalColors.inputDarkFill
                                  : GlobalColors.inputLightFill)
                              .withOpacity(isDark ? 0.45 : 0.7),
                          value: sftpController.rememberLogin.value,
                          onChanged: (value) async {
                            final isChecked = value ?? false;
                            await sftpController.updateRememberPreference(
                              isChecked,
                            );
                          },
                          title: Text(
                            'Lưu thông tin đăng nhập',
                            style: GlobalTextStyles.bodyMedium(isDark: isDark)
                                .copyWith(fontWeight: FontWeight.w500),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: GlobalColors.accentByIsDark(isDark),
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          final int port =
                              int.tryParse(portController.text.trim()) ?? 0;
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Đăng nhập',
                          style: GlobalTextStyles.bodyMedium(isDark: isDark)
                              .copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () => sftpController.errorMessage.value.isEmpty
                            ? const SizedBox.shrink()
                            : Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: (isDark
                                          ? GlobalColors.cardDarkBg
                                          : GlobalColors.cardLightBg)
                                      .withOpacity(isDark ? 0.6 : 0.8),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: GlobalColors.accentByIsDark(isDark)
                                        .withOpacity(0.45),
                                  ),
                                ),
                                child: Text(
                                  sftpController.errorMessage.value,
                                  textAlign: TextAlign.center,
                                  style: GlobalTextStyles.bodyMedium(isDark: isDark)
                                      .copyWith(
                                    color: GlobalColors.accentByIsDark(isDark),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      Obx(
                        () {
                          final shouldShowClear =
                              sftpController.rememberLogin.value ||
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor:
                                  GlobalColors.accentByIsDark(isDark),
                              side: BorderSide(
                                color: GlobalColors.accentByIsDark(isDark)
                                    .withOpacity(0.65),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              'Xóa thông tin đã lưu',
                              style: GlobalTextStyles.bodyMedium(isDark: isDark)
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
    final Color borderColor =
        isDark ? GlobalColors.borderDark : GlobalColors.borderLight;
    final Color fillColor =
        isDark ? GlobalColors.inputDarkFill.withOpacity(0.55) : Colors.white;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GlobalTextStyles.bodyMedium(isDark: isDark).copyWith(
          color:
              isDark ? GlobalColors.darkSecondaryText : GlobalColors.lightSecondaryText,
        ),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor.withOpacity(0.55), width: 1.1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: GlobalColors.accentByIsDark(isDark),
            width: 2.2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      style: GlobalTextStyles.bodyMedium(isDark: isDark).copyWith(
        color:
            isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText,
      ),
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
