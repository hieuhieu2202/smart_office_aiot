part of 'package:smart_factory/screen/home/widget/smt/stencil_monitor/stencil_monitor_screen.dart';

class _RunningLineTile extends StatelessWidget {
  const _RunningLineTile({
    required this.detail,
    required this.hourDiff,
    required this.accent,
    this.onTap,
    this.dense = true,
  });

  final StencilDetail detail;
  final double hourDiff;
  final Color accent;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final hoursText = hourDiff.toStringAsFixed(2);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                detail.lineName ?? detail.location ?? detail.stencilSn,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: dense ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withOpacity(0.55)),
              ),
              child: Text(
                '$hoursText h',
                style: GoogleFonts.robotoMono(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _DetailRow(label: 'Stencil SN', value: detail.stencilSn ?? '--'),
        _DetailRow(
          label: 'Start',
          value: detail.startTime != null
              ? DateFormat('yyyy-MM-dd HH:mm:ss').format(detail.startTime!)
              : 'Unknown',
        ),
        _DetailRow(label: 'Use times', value: '${detail.totalUseTimes ?? 0}'),
      ],
    );

    if (onTap == null) {
      return Container(
        margin: EdgeInsets.only(bottom: dense ? 12 : 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.5)),
          gradient: LinearGradient(
            colors: [accent.withOpacity(0.18), Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: content,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: EdgeInsets.only(bottom: dense ? 12 : 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.5)),
          gradient: LinearGradient(
            colors: [accent.withOpacity(0.18), Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: content,
      ),
    );
  }
}
