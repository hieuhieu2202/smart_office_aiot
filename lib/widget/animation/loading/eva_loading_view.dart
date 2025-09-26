import 'package:flutter/material.dart';

import 'eva_scanner.dart';

class EvaLoadingView extends StatelessWidget {
  const EvaLoadingView({super.key, this.size = 220, this.alignment = Alignment.center, this.padding});

  final double size;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget content = SizedBox.square(
      dimension: size,
      child: EvaScanner(size: size),
    );
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    return Align(
      alignment: alignment,
      widthFactor: 1,
      heightFactor: 1,
      child: FittedBox(
        fit: BoxFit.contain,
        child: content,
      ),
    );
  }
}
