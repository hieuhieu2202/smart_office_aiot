import 'dart:io';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:camera_android_camerax/camera_android_camerax.dart';
import 'package:camera_windows/camera_windows.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/screen/login/controller/login_controller.dart';
import 'package:smart_factory/screen/login/controller/user_profile_manager.dart';
import 'package:smart_factory/screen/navbar/controller/navbar_controller.dart';
import 'package:smart_factory/screen/setting/controller/setting_controller.dart';
import 'package:smart_factory/screen/splash/splash.dart';
import 'package:smart_factory/screen/login/login.dart';
import 'package:smart_factory/screen/navbar/navbar.dart';
import 'package:smart_factory/screen/camera/camera_capture_page.dart';
import 'package:smart_factory/lang/controller/language_controller.dart';
import 'package:smart_factory/lang/language_selection_screen.dart';
import 'package:smart_factory/generated/l10n.dart';
import 'package:smart_factory/service/auth/token_manager.dart';
import 'package:syncfusion_flutter_core/core.dart';

import 'screen/notification/controller/notification_controller.dart';





class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    if (Platform.isWindows) {
      CameraPlatform.instance = CameraWindows();
    } else if (Platform.isAndroid) {
      AndroidCameraCameraX.registerWith();
    }
  }

  HttpOverrides.global = MyHttpOverrides();
  await GetStorage.init();
  Get.put(NavbarController());
  Get.put(LoginController());
  Get.put(UserProfileManager());
  Get.put(SettingController());
  Get.put(LanguageController());
  Get.put(NotificationController(), permanent: true);
  // // key SyncfusionLicense để đọc file pdf
  // SyncfusionLicense.registerLicense('Ngo9BigBOggjHTQxAR8/V1JEaF1cWWhAYVppR2Nbek5xdF9HZlZRRmY/P1ZhSXxWdkxjW31ccXJVRGZcWUF9XEI=');
  runApp(const MyApp());

  // runApp(
  //   DevicePreview(
  //     enabled: true, // hoặc: !kReleaseMode,
  //     builder: (context) => const MyApp(),
  //   ),
  // );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingController settingController = Get.find<SettingController>();
    final LanguageController languageController =
        Get.find<LanguageController>();

    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode:
            settingController.isDarkMode.value
                ? ThemeMode.dark
                : ThemeMode.light,
        theme: ThemeData.light().copyWith(
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalColors.primaryButtonLight,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        darkTheme: ThemeData.dark().copyWith(
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalColors.primaryButtonDark,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        locale: languageController.currentLocale.value,
        localeResolutionCallback: (locale, supportedLocales) {
          return supportedLocales.contains(locale)
              ? locale
              : const Locale('vi');
        },
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: '/splash',
        getPages: [
          GetPage(name: '/splash', page: () => const SplashScreen()),
          GetPage(
            name: '/select-language',
            page: () => const LanguageSelectionScreen(),
          ),
          GetPage(name: '/login', page: () => const LoginScreen()),
          GetPage(name: '/navbar', page: () => const NavbarScreen()),
          GetPage(name: '/camera-capture', page: () => const CameraCapturePage()),
        ],
      ),
    );
  }
}
