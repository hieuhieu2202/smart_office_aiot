part of 'package:smart_factory/screen/home/widget/smt/stencil_monitor/stencil_monitor_screen.dart';

class _InsightMetric {
  const _InsightMetric({
    required this.label,
    required this.value,
    required this.description,
    required this.accent,
  });

  final String label;
  final String value;
  final String description;
  final Color accent;
}

class _InsightsStrip extends StatelessWidget {
  const _InsightsStrip({required this.items});

  final List<_InsightMetric> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, index) {
          final metric = items[index];
          return Container(
            width: 168,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: metric.accent.withOpacity(0.5)),
              gradient: LinearGradient(
                colors: [
                  metric.accent.withOpacity(0.18),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: metric.accent.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    color: metric.accent,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  metric.value,
                  style: GoogleFonts.orbitron(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metric.description,
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
