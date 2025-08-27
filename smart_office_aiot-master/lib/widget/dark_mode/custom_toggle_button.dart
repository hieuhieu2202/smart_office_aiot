import 'dart:ui';
import 'package:flutter/material.dart';

class CustomToggleButton extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggle;

  const CustomToggleButton({
    super.key,
    required this.isDarkMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 60, // Kích thước tương tự 7em trong CSS
        height: 35,
        child: Stack(
          children: [
            // Container (background của toggle)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2B4360) : const Color(0xFF83CBD8),
                borderRadius: BorderRadius.circular(17.5),
              ),
            ),
            // Button (Sun/Moon)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              left: isDarkMode ? 28 : 2.333,
              top: 2.333,
              child: Stack(
                alignment: Alignment.center, // Căn giữa mặt trăng
                children: [
                  // Sun
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: isDarkMode ? 0 : 1,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 30.334,
                          height: 30.334,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFF8E664),
                          ),
                        ),
                        Container(
                          width: 23.334,
                          height: 23.334,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x49F6FEF7),
                          ),
                        ),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFCF4B9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Moon
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: isDarkMode ? 1 : 0,
                    child: Stack(
                      alignment: Alignment.center, // Căn giữa mặt trăng
                      children: [
                        Container(
                          width: 30.334,
                          height: 30.334,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFCCE6EE),
                          ),
                        ),
                        // Moon patches (điều chỉnh vị trí để căn giữa)
                        Positioned(
                          left: -8.585, // Điều chỉnh từ 6.585 để căn giữa
                          top: -8.339, // Điều chỉnh từ 6.839 để căn giữa
                          child: Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFA6CAD0))),
                        ),
                        Positioned(
                          left: -12.228, // Điều chỉnh từ 2.942
                          top: 5.117, // Điều chỉnh từ 20.295
                          child: Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFA6CAD0))),
                        ),
                        Positioned(
                          left: -18.578, // Điều chỉnh từ -3.408
                          top: -4.791, // Điều chỉnh từ 10.387
                          child: Container(width: 2, height: 2, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFA6CAD0))),
                        ),
                        Positioned(
                          left: -0.513, // Điều chỉnh từ 14.657
                          top: 6.053, // Điều chỉnh từ 21.231
                          child: Container(width: 2, height: 2, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFA6CAD0))),
                        ),
                        Positioned(
                          left: -18.578, // Điều chỉnh từ -3.408
                          top: 10.668, // Điều chỉnh từ 25.846
                          child: Container(width: 2, height: 2, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFA6CAD0))),
                        ),
                        Positioned(
                          left: -1.513, // Điều chỉnh từ 13.657
                          top: -2.305, // Điều chỉnh từ 12.873
                          child: Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFA6CAD0))),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Cloud
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isDarkMode ? 0 : 1,
              child: CustomPaint(
                size: const Size(60.667, 35),
                painter: CloudPainter(),
              ),
            ),
            // Stars
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isDarkMode ? 1 : 0,
              child: CustomPaint(
                size: const Size(60.667, 35),
                painter: StarsPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFFFFF);
    final path = Path()
      ..moveTo(46.34, 12.875)
      ..cubicTo(47.43, 12.875, 48.39, 13.315, 49.08, 14.015)
      ..cubicTo(49.23, 14.165, 49.37, 14.005, 49.47, 13.635)
      ..cubicTo(49.92, 12.055, 51.28, 11.375, 52.48, 11.875)
      ..cubicTo(52.51, 11.885, 52.08, 12.565, 52.48, 12.935)
      ..cubicTo(53.28, 13.675, 54.53, 13.415, 54.87, 14.155)
      ..cubicTo(55.21, 14.895, 54.17, 15.935, 54.23, 15.975)
      ..cubicTo(54.29, 16.015, 55.87, 16.355, 56.34, 16.875)
      ..cubicTo(56.81, 17.395, 57.36, 18.935, 55.72, 19.875)
      ..cubicTo(54.54, 20.565, 53.36, 20.355, 52.48, 20.155)
      ..cubicTo(51.6, 19.955, 51.69, 18.355, 51.72, 18.375)
      ..cubicTo(51.75, 18.395, 50.72, 20.155, 49.48, 20.155)
      ..cubicTo(48.24, 20.155, 47.28, 19.715, 46.59, 19.015)
      ..cubicTo(45.9, 18.315, 45.08, 18.735, 44.24, 18.615)
      ..cubicTo(41.81, 18.315, 42.91, 15.935, 43.04, 15.655)
      ..cubicTo(43.17, 15.375, 44.24, 12.875, 46.34, 12.875)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFDEF8FF);
    final List<Path> stars = [
      Path()
        ..moveTo(20.646, 1.73)
        ..lineTo(20.438, 2.289)
        ..lineTo(19.872, 2.269)
        ..lineTo(20.33, 2.663)
        ..lineTo(20.122, 3.222)
        ..lineTo(20.607, 2.861)
        ..lineTo(21.065, 3.255)
        ..lineTo(20.896, 2.723)
        ..lineTo(21.381, 2.362)
        ..lineTo(20.815, 2.342)
        ..close(),
      Path()
        ..moveTo(19.6, 11.033)
        ..lineTo(19.095, 10.976)
        ..lineTo(18.995, 10.504)
        ..lineTo(18.764, 10.964)
        ..lineTo(18.259, 10.904)
        ..lineTo(18.659, 11.233)
        ..lineTo(18.428, 11.693)
        ..lineTo(18.864, 11.436)
        ..lineTo(19.264, 11.762)
        ..lineTo(19.159, 11.29)
        ..close(),
      Path()
        ..moveTo(19.592, 28.41)
        ..lineTo(20.052, 28.245)
        ..lineTo(20.337, 28.61)
        ..lineTo(20.343, 28.117)
        ..lineTo(20.803, 27.953)
        ..lineTo(20.322, 27.839)
        ..lineTo(19.841, 27.725)
        ..lineTo(20.126, 28.09)
        ..lineTo(19.645, 27.976)
        ..lineTo(19.93, 28.341)
        ..close(),
      Path()
        ..moveTo(9.092, 0.063)
        ..lineTo(8.99, 0.663)
        ..lineTo(9.505, 0.385)
        ..lineTo(8.893, 0.27)
        ..lineTo(8.791, -0.337)
        ..lineTo(8.544, 0.235)
        ..lineTo(7.93, 0.12)
        ..lineTo(8.376, 0.544)
        ..lineTo(8.13, 1.117)
        ..lineTo(8.646, 0.843)
        ..close(),
      Path()
        ..moveTo(7.481, 14.132)
        ..lineTo(7.595, 13.512)
        ..lineTo(8.187, 13.429)
        ..lineTo(7.638, 13.104)
        ..lineTo(7.752, 12.484)
        ..lineTo(7.314, 12.948)
        ..lineTo(6.765, 12.623)
        ..lineTo(7.046, 13.184)
        ..lineTo(6.608, 13.651)
        ..lineTo(7.2, 13.568)
        ..close(),
      Path()
        ..moveTo(4.741, 26.736)
        ..lineTo(4.786, 27.46)
        ..lineTo(4.146, 27.718)
        ..lineTo(4.846, 27.929)
        ..lineTo(4.891, 28.653)
        ..lineTo(5.251, 28.013)
        ..lineTo(5.951, 28.224)
        ..lineTo(5.49, 27.671)
        ..lineTo(5.849, 27.03)
        ..lineTo(5.212, 27.288)
        ..close(),
      Path()
        ..moveTo(1.427, 4.637)
        ..lineTo(1.111, 5.092)
        ..lineTo(0.611, 4.948)
        ..lineTo(0.934, 5.404)
        ..lineTo(0.622, 5.859)
        ..lineTo(1.138, 5.644)
        ..lineTo(0.961, 6.1)
        ..lineTo(0.938, 5.548)
        ..lineTo(1.454, 5.337)
        ..lineTo(0.95, 5.189)
        ..close(),
      Path()
        ..moveTo(-1.367, 13.291)
        ..lineTo(-0.88, 13.862)
        ..lineTo(-0.22, 13.591)
        ..lineTo(-0.593, 14.258)
        ..lineTo(-0.105, 14.829)
        ..lineTo(-0.833, 14.611)
        ..lineTo(-0.461, 15.273)
        ..lineTo(-0.414, 14.524)
        ..lineTo(-1.142, 14.306)
        ..lineTo(-0.482, 14.04)
        ..close(),
    ];
    for (var star in stars) {
      canvas.drawPath(star, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}