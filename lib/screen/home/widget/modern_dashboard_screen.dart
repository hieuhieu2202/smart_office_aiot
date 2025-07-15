import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ModernDashboardScreen extends StatefulWidget {
  const ModernDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ModernDashboardScreen> createState() => _ModernDashboardScreenState();
}

class _ModernDashboardScreenState extends State<ModernDashboardScreen> {
  bool showFilter = false;
  bool refreshing = false;
  String selectedMachine = 'AOI-001';

  final List<String> machines = [
    'AOI-001',
    'AOI-002',
    'AOI-003',
    'AOI-004',
    'AOI-005',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
          floatingActionButton: AnimatedScale(
            scale: showFilter ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: FloatingActionButton(
              heroTag: 'filterFab',
              onPressed: () => setState(() => showFilter = true),
              backgroundColor: const Color(0xFF4CAF50),
              child: const Icon(Icons.filter_list, color: Colors.white),
            ),
          ),
          body: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSummaryCard(isDark),
                    const SizedBox(height: 14),
                    _buildRuntimeChart(isDark),
                    const SizedBox(height: 18),
                    _buildOutputChart(isDark),
                    const SizedBox(height: 18),
                    _buildMachineList(isDark),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showFilter) _buildFilterPanel(isDark),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 44, left: 16, right: 12, bottom: 16),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3F51B5), Color(0xFF2196F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Production Line A',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'PCB-V2.1',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 6),
                _buildMachineDropdown(),
              ],
            ),
          ),
          IconButton(
            icon: refreshing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              setState(() => refreshing = true);
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) setState(() => refreshing = false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMachineDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedMachine,
        dropdownColor: Colors.white,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        items: machines
            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
            .toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() => selectedMachine = val);
          }
        },
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    return Card(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Text(
              'Summary Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SummaryItem(label: 'YR', value: '95.2%'),
                _SummaryItem(label: 'PASS', value: '1,847'),
                _SummaryItem(label: 'FAIL', value: '93'),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SummaryItem(label: 'FPR', value: '4.8%'),
                _SummaryItem(label: 'RR', value: '98.1%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuntimeChart(bool isDark) {
    final bars = [80.0, 95.0, 70.0, 85.0, 90.0];
    final idle = [20.0, 5.0, 30.0, 15.0, 10.0];
    final times = ['08:00', '10:00', '12:00', '14:00', '16:00'];
    final labelColor = isDark ? Colors.white70 : Colors.black87;

    return Card(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Runtime Analysis - $selectedMachine',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, horizontalInterval: 20),
                  titlesData: FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) => Text(
                          meta.formattedValue,
                          style: TextStyle(fontSize: 11, color: labelColor),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          return idx < times.length
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(times[idx], style: TextStyle(color: labelColor, fontSize: 12)),
                                )
                              : const SizedBox();
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(times.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: bars[i],
                          color: const Color(0xFF4CAF50),
                          width: 10,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        BarChartRodData(
                          toY: idle[i],
                          color: const Color(0xFFF44336),
                          width: 10,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                      showingTooltipIndicators: [0, 1],
                    );
                  }),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIdx, rod, rodIdx) {
                        final hour = times[group.x.toInt()];
                        return BarTooltipItem(
                          '${rodIdx == 0 ? 'Run' : 'Idle'}\n$hour: ${rod.toY}%',
                          const TextStyle(color: Colors.white, fontSize: 13),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _Legend(color: Color(0xFF4CAF50), label: 'Run'),
                SizedBox(width: 20),
                _Legend(color: Color(0xFFF44336), label: 'Idle'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputChart(bool isDark) {
    final pass = [340.0, 368.0, 312.0, 352.0, 360.0];
    final fail = [18.0, 12.0, 28.0, 15.0, 10.0];
    final times = ['08:00', '10:00', '12:00', '14:00', '16:00'];
    final labelColor = isDark ? Colors.white70 : Colors.black87;

    return Card(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Output Analysis - $selectedMachine',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, horizontalInterval: 50),
                  titlesData: FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) => Text(
                          meta.formattedValue,
                          style: TextStyle(fontSize: 11, color: labelColor),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          return idx < times.length
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(times[idx], style: TextStyle(color: labelColor, fontSize: 12)),
                                )
                              : const SizedBox();
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(times.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: pass[i],
                          color: const Color(0xFF2196F3),
                          width: 10,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        BarChartRodData(
                          toY: fail[i],
                          color: const Color(0xFFFF9800),
                          width: 10,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                      showingTooltipIndicators: [0, 1],
                    );
                  }),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIdx, rod, rodIdx) {
                        final hour = times[group.x.toInt()];
                        return BarTooltipItem(
                          '${rodIdx == 0 ? 'PASS' : 'FAIL'}\n$hour: ${rod.toY}',
                          const TextStyle(color: Colors.white, fontSize: 13),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _Legend(color: Color(0xFF2196F3), label: 'PASS'),
                SizedBox(width: 20),
                _Legend(color: Color(0xFFFF9800), label: 'FAIL'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMachineList(bool isDark) {
    final items = [
      {'name': 'AOI-001', 'status': 'Running', 'time': '14:30:25', 'eff': '95.2%'},
      {'name': 'AOI-002', 'status': 'Idle', 'time': '12:15:10', 'eff': '87.5%'},
      {'name': 'AOI-003', 'status': 'Maintenance', 'time': '10:45:30', 'eff': '92.1%'},
      {'name': 'AOI-004', 'status': 'Running', 'time': '15:22:18', 'eff': '89.7%'},
      {'name': 'AOI-005', 'status': 'Idle', 'time': '11:30:45', 'eff': '91.3%'},
    ];

    return Card(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Machine Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...items.map((m) => ListTile(
                  onTap: () => setState(() => selectedMachine = m['name'] as String),
                  selected: selectedMachine == m['name'],
                  selectedTileColor: const Color(0xFFE3F2FD),
                  title: Text('${m['name']} - ${m['status']}'),
                  subtitle: Text('Time: ${m['time']}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        m['eff'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                          fontSize: 18,
                        ),
                      ),
                      const Text('Efficiency', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel(bool isDark) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      right: showFilter ? 0 : -320,
      top: 0,
      bottom: 0,
      width: 320,
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 12,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => showFilter = false),
                  )
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Model Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Date Range',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                      onPressed: () => setState(() => showFilter = false),
                      child: const Text('Apply'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF44336)),
                      onPressed: () => setState(() => showFilter = false),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF2196F3),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 13, color: textColor)),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
