import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_factory/config/global_text_style.dart';
import '../../config/global_color.dart';
import 'controller/splash_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fController;
  late Animation<Offset> _fAnimation;
  late AnimationController _iBeController;
  late Animation<Offset> _iBeAnimation;
  late AnimationController _iToController;
  late Animation<Offset> _iToAnimation;
  late AnimationController _textController;
  late Animation<Offset> _textAnimation;

  @override
  void initState() {
    super.initState();
    // Animation cho chữ F (từ trái)
    _fController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _fAnimation = Tween<Offset>(
      begin: const Offset(-3.5, 0.0),
      end: const Offset(0.3, 0.0),
    ).animate(CurvedAnimation(parent: _fController, curve: Curves.easeOut))
      ..addListener(() => setState(() {}));
    _fController.forward(from: 0.2);

    _iBeController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _iBeAnimation = Tween<Offset>(
      begin: const Offset(0.0, -2.0),
      end: const Offset(-0.4, 0.0),
    ).animate(CurvedAnimation(parent: _iBeController, curve: Curves.easeOut))
      ..addListener(() => setState(() {}));
    _iBeController.forward(from: 0.2);

    // Animation cho chữ I (từ phải)
    _iToController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _iToAnimation = Tween<Offset>(
      begin: const Offset(5.0, 0.0),
      end: const Offset(-0.6, 0.0),
    ).animate(CurvedAnimation(parent: _iToController, curve: Curves.easeOut))
      ..addListener(() => setState(() {}));
    _iToController.forward(from: 0.2);

    // Animation cho dòng chữ MBD-AIOT (fade-in)
    _textController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _textAnimation = Tween<Offset>(
      begin: const Offset(5.0, 0.0),
      end: const Offset(0.0, -0.7),
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut))
      ..addListener(() => setState(() {}));
    _textController.forward(from: 0.2);

    // Khởi tạo controller
    Get.put(SplashController());
  }

  @override
  void dispose() {
    _fController.dispose();
    _iBeController.dispose();
    _iToController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SplashController>();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? GlobalColors.backgroundGradient(
            color1: GlobalColors.bodyDarkBg,
            color2: GlobalColors.gradientDarkStart,
            color3: GlobalColors.gradientDarkEnd,
            color4: GlobalColors.darkBackground,
          )
              : GlobalColors.backgroundGradient(
            color1: GlobalColors.bodyLightBg,
            color2: GlobalColors.gradientLightStart,
            color3: GlobalColors.gradientLightEnd,
            color4: GlobalColors.lightBackground,
          ),
        ),
        child: Center(
          child: Obx(
                () => AnimatedOpacity(
              opacity: controller.opacity.value,
              duration: const Duration(milliseconds: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SlideTransition(
                        position: _fAnimation,
                        child: Image.asset(
                          'assets/images/f.png',
                          height: 160,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 2),
                      SlideTransition(
                        position: _iBeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 0),
                          child: Image.asset(
                            'assets/images/ingan.png',
                            height: 160,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      SlideTransition(
                        position: _iToAnimation,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 0),
                          child: Image.asset(
                            'assets/images/idai.png',
                            height: 160,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SlideTransition(
                    position: _textAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0, left: 80),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'MBD',
                              style: GlobalTextStyles.contentStyle().copyWith(
                                color: GlobalColors.mbdColor,
                              ),
                            ),
                            TextSpan(
                              text: '-',
                              style: GlobalTextStyles.contentStyle().copyWith(
                                foreground: Paint()
                                  ..shader = LinearGradient(
                                    colors: [
                                      GlobalColors.mbdColor,
                                      GlobalColors.aiotColor,
                                    ],
                                  ).createShader(
                                    const Rect.fromLTWH(0, 0, 200, 70),
                                  ),
                              ),
                            ),
                            TextSpan(
                              text: 'AIOT',
                              style: GlobalTextStyles.contentStyle().copyWith(
                                color: GlobalColors.aiotColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
