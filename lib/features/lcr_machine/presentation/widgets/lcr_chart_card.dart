import 'package:flutter/material.dart';

class LcrChartCard extends StatelessWidget {
  const LcrChartCard({
    super.key,
    required this.title,
    required this.child,
    this.height,
    this.backgroundColor,
    this.backgroundGradient,
    this.padding,
  });

  final String title;
  final Widget child;
  final double? height;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);
    final decoration = BoxDecoration(
      borderRadius: borderRadius,
      color: backgroundGradient == null
          ? backgroundColor ?? const Color(0xFF03132D)
          : null,
      gradient: backgroundGradient,
      border: Border.all(color: Colors.white10, width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66031A35),
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
    );

    return Container(
      height: height,
      decoration: decoration,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Padding(
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
      ),
    );
  }
}
