import 'package:flutter/material.dart';

class LcrChartCard extends StatelessWidget {
  const LcrChartCard({
    super.key,
    required this.title,
    required this.child,
    this.height,
    this.backgroundAsset,
    this.overlayGradient,
    this.overlayColor,
    this.padding,
  });

  final String title;
  final Widget child;
  final double? height;
  final String? backgroundAsset;
  final List<Color>? overlayGradient;
  final Color? overlayColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);
    final defaultOverlay = const Color(0xFF041C3B).withOpacity(0.85);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white12, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66031A35),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (backgroundAsset != null)
              Positioned.fill(
                child: Image.asset(
                  backgroundAsset!,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: overlayColor ?? defaultOverlay,
                  gradient: overlayGradient != null
                      ? LinearGradient(
                          colors: overlayGradient!,
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                ),
              ),
            ),
            Padding(
              padding:
                  padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
