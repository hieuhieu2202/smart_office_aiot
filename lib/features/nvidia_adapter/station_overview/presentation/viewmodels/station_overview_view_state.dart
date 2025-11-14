import '../../domain/entities/station_overview_entities.dart';

class StationOverviewDashboardViewState {
  StationOverviewDashboardViewState({
    required this.overviewData,
    required this.analysisData,
    required this.detailData,
    required this.rateConfig,
  }) {
    _flatten();
  }

  final List<StationOverviewData> overviewData;
  final List<StationAnalysisData> analysisData;
  final List<StationDetailData> detailData;
  final StationRateConfig rateConfig;

  late final List<StationSummary> stations;

  void _flatten() {
    final List<StationSummary> buffer = <StationSummary>[];
    for (final StationOverviewData product in overviewData) {
      for (final StationGroupData group in product.groupDatas) {
        for (final StationData station in group.stationDatas) {
          buffer.add(
            StationSummary(
              productName: product.productName,
              groupName: group.groupName,
              data: station,
              status: _resolveStatus(station),
            ),
          );
        }
      }
    }
    stations = buffer;
  }

  int get totalStations => stations.length;

  Map<StationStatus, int> get statusCounts {
    final Map<StationStatus, int> counts = <StationStatus, int>{
      StationStatus.error: 0,
      StationStatus.warning: 0,
      StationStatus.normal: 0,
      StationStatus.offline: 0,
    };
    for (final StationSummary summary in stations) {
      counts.update(summary.status, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  List<StationChartPoint> get failQuantitySeries {
    final Map<String, num> totals = <String, num>{};
    for (final StationSummary summary in stations) {
      totals.update(summary.data.stationName, (value) => value + summary.data.failQty,
          ifAbsent: () => summary.data.failQty);
    }
    return totals.entries
        .map((entry) => StationChartPoint(entry.key, entry.value))
        .toList()
      ..sort((a, b) => a.category.compareTo(b.category));
  }

  List<StationChartPoint> analysisByErrorCode() {
    final Map<String, num> totals = <String, num>{};
    for (final StationAnalysisData item in analysisData) {
      totals.update(item.errorCode, (value) => value + item.failCount,
          ifAbsent: () => item.failCount);
    }
    return totals.entries
        .map((entry) => StationChartPoint(entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  List<StationTrendPoint> analysisTrendByDate() {
    final Map<String, num> totals = <String, num>{};
    for (final StationAnalysisData item in analysisData) {
      totals.update(item.classDate, (value) => value + item.failCount,
          ifAbsent: () => item.failCount);
    }
    final List<MapEntry<String, num>> sorted = totals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return sorted
        .map((entry) => StationTrendPoint(entry.key, entry.value))
        .toList();
  }

  StationStatus _resolveStatus(StationData data) {
    if (data.input <= 0) {
      return StationStatus.offline;
    }
    final double yr = data.yieldRate;
    final double rr = data.retestRate;

    if (yr < rateConfig.yieldRateLower || rr > rateConfig.retestRateUpper) {
      return StationStatus.error;
    }
    if ((yr >= rateConfig.yieldRateLower && yr < rateConfig.yieldRateUpper) ||
        (rr > rateConfig.retestRateLower &&
            rr <= rateConfig.retestRateUpper)) {
      return StationStatus.warning;
    }
    return StationStatus.normal;
  }
}

class StationSummary {
  StationSummary({
    required this.productName,
    required this.groupName,
    required this.data,
    required this.status,
  });

  final String productName;
  final String groupName;
  final StationData data;
  final StationStatus status;

  double get yieldRate => data.yieldRate;
  double get retestRate => data.retestRate;
}

class StationChartPoint {
  const StationChartPoint(this.category, this.value);

  final String category;
  final num value;
}

class StationTrendPoint extends StationChartPoint {
  const StationTrendPoint(super.category, super.value);
}
