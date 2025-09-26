import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'eva_scanner.dart';

class EvaLoadingView extends StatelessWidget {
  const EvaLoadingView({
    super.key,
    this.size = 220,
    this.alignment = Alignment.center,
    this.padding,
  });

  /// The natural size of the EVA robot animation. The widget will try to honor
  /// this dimension and will only scale down if its parent provides less space.
  final double size;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.hasBoundedWidth ? constraints.maxWidth : double.infinity;
        final maxHeight = constraints.hasBoundedHeight ? constraints.maxHeight : double.infinity;

        double dimension = size;
        final available = math.min(maxWidth, maxHeight);
        if (available.isFinite && available > 0) {
          dimension = math.min(size, available);
        }

        return SizedBox(
          width: dimension,
          height: dimension,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox.square(
              dimension: size,
              child: EvaScanner(size: size),
            ),
          ),
        );
      },
    );
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    return Align(
      alignment: alignment,
      child: content,
    );
  }
}
