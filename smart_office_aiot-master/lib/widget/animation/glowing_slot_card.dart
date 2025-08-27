import 'package:flutter/cupertino.dart';

class GlowingSlotCard extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Color baseColor;

  const GlowingSlotCard({
    super.key,
    required this.child,
    required this.isActive,
    required this.baseColor,
  });

  @override
  State<GlowingSlotCard> createState() => _GlowingSlotCardState();
}

class _GlowingSlotCardState extends State<GlowingSlotCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final animatedColor = widget.baseColor.withOpacity(_animation.value);
        return Container(
          decoration: BoxDecoration(
            color: animatedColor.withOpacity(0.07),
            border: Border.all(
              color: animatedColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: widget.child,
        );
      },
    );
  }
}
