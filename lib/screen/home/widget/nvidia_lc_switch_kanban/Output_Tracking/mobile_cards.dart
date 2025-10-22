import 'package:flutter/material.dart';

import 'cells.dart';
import 'series_utils.dart';

class OtMobileList extends StatelessWidget {
  const OtMobileList({
    super.key,
    required this.groups,
    required this.hours,
    required this.modelNameByGroup,
    required this.passByGroup,
    required this.yrByGroup,
    required this.rrByGroup,
    required this.wipByGroup,
    required this.totalPassByGroup,
    required this.totalFailByGroup,
  });

  final List<String> groups;
  final List<String> hours;
  final Map<String, String> modelNameByGroup;
  final Map<String, List<double>> passByGroup;
  final Map<String, List<double>> yrByGroup;
  final Map<String, List<double>> rrByGroup;
  final Map<String, int> wipByGroup;
  final Map<String, int> totalPassByGroup;
  final Map<String, int> totalFailByGroup;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final station = groups[index];
        final model = modelNameByGroup[station]?.trim();
        final wip = wipByGroup[station] ?? 0;
        final totalPass = totalPassByGroup[station] ?? 0;
        final totalFail = totalFailByGroup[station] ?? 0;

        final pass = ensureSeries(station, passByGroup, hours.length);
        final yr = ensureSeries(station, yrByGroup, hours.length);
        final rr = ensureSeries(station, rrByGroup, hours.length);

        return _OtMobileCard(
          station: station,
          model: model,
          wip: wip,
          totalPass: totalPass,
          totalFail: totalFail,
          hours: hours,
          pass: pass,
          yr: yr,
          rr: rr,
        );
      },
    );
  }
}

class _OtMobileCard extends StatelessWidget {
  const _OtMobileCard({
    required this.station,
    required this.model,
    required this.wip,
    required this.totalPass,
    required this.totalFail,
    required this.hours,
    required this.pass,
    required this.yr,
    required this.rr,
  });

  final String station;
  final String? model;
  final int wip;
  final int totalPass;
  final int totalFail;
  final List<String> hours;
  final List<double> pass;
  final List<double> yr;
  final List<double> rr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0F253E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (model != null && model!.isNotEmpty)
                  _Pill(label: 'MODEL', value: model!),
                _Pill(label: 'STATION', value: station),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _MetricChip(label: 'WIP', value: wip.toString(), color: Colors.blue),
                const SizedBox(width: 10),
                _MetricChip(label: 'PASS', value: totalPass.toString(), color: Colors.green),
                const SizedBox(width: 10),
                _MetricChip(label: 'FAIL', value: totalFail.toString(), color: Colors.redAccent),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Production hours',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _HourList(hours: hours, pass: pass, yr: yr, rr: rr),
          ],
        ),
      ),
    );
  }
}

class _HourList extends StatelessWidget {
  const _HourList({
    required this.hours,
    required this.pass,
    required this.yr,
    required this.rr,
  });

  final List<String> hours;
  final List<double> pass;
  final List<double> yr;
  final List<double> rr;

  @override
  Widget build(BuildContext context) {
    if (hours.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(hours.length, (index) {
          final label = formatHourRange(hours[index]);
          return Container(
            width: 160,
            margin: EdgeInsets.only(right: index == hours.length - 1 ? 0 : 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: .2,
                      ),
                ),
                const SizedBox(height: 12),
                TripleCell(
                  pass: pass[index],
                  yr: yr[index],
                  rr: rr[index],
                  compact: false,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(.35)),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  letterSpacing: .3,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
