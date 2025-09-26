import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'eva_scanner.dart';

class EvaLoadingView extends StatelessWidget {
  const EvaLoadingView({super.key, this.size = 220, this.alignment = Alignment.center, this.padding});

  final double size;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.hasBoundedWidth ? constraints.maxWidth : size;
        final maxHeight = constraints.hasBoundedHeight ? constraints.maxHeight : size;

        double dimension = math.min(size, math.min(maxWidth, maxHeight));
        if (dimension.isInfinite || dimension <= 0) {
          dimension = size;
        }

        return SizedBox.square(
          dimension: dimension,
          child: EvaScanner(size: dimension),
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
