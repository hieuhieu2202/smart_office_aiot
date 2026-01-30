import '../../domain/entities/te_report.dart';
import '../../domain/entities/te_retest_rate.dart';
import '../../domain/entities/te_top_error.dart';
import '../../domain/entities/te_yield_rate.dart';
import '../../domain/repositories/te_management_repository.dart';
import '../datasources/te_management_remote_data_source.dart';
import '../models/te_report_models.dart';

class TEManagementRepositoryImpl implements TEManagementRepository {
  TEManagementRepositoryImpl(this._remoteDataSource);

  final TEManagementRemoteDataSource _remoteDataSource;

  @override
  Future<List<TEReportGroupEntity>> fetchReport({
    required String modelSerial,
    required String range,
    String model = '',
  }) async {
    final rows = await _remoteDataSource.fetchReport(
      modelSerial: modelSerial,
      range: range,
      model: model,
    );
    final Map<String, List<TEReportRowModel>> grouped = {};
    for (final row in rows) {
      final key = row.modelName.trim().isEmpty ? '(N/A)' : row.modelName.trim();
      grouped.putIfAbsent(key, () => []).add(row);
    }
    final List<TEReportGroupEntity> groups = grouped.entries.map((entry) {
      final sorted = entry.value
        ..sort((a, b) => a.groupName.compareTo(b.groupName));
      return TEReportGroupModel.fromRows(sorted);
    }).toList()
      ..sort((a, b) => a.modelName.compareTo(b.modelName));
    return groups;
  }

  @override
  Future<List<String>> fetchModelNames({required String modelSerial}) {
    return _remoteDataSource.fetchModelNames(modelSerial: modelSerial);
  }

  @override
  Future<TEErrorDetailEntity?> fetchErrorDetail({
    required String range,
    required String model,
    required String group,
  }) {
    return _remoteDataSource.fetchErrorDetail(
      range: range,
      model: model,
      group: group,
    );
  }

  @override
  Future<TEErrorDetailEntity?> fetchRetestRateErrorDetail({
    required String date,
    required String shift,
    required String model,
    required String group,
  }) {
    return _remoteDataSource.fetchRetestRateErrorDetail(
      date: date,
      shift: shift,
      model: model,
      group: group,
    );
  }

  @override
  Future<TERetestDetailEntity> fetchRetestRateReport({
    required String modelSerial,
    required String range,
    String model = '',
  }) {
    return _remoteDataSource.fetchRetestRateReport(
      modelSerial: modelSerial,
      range: range,
      model: model,
    );
  }

  @override
  Future<TEYieldDetailEntity> fetchYieldRateReport({
    required String modelSerial,
    required String range,
    String model = '',
  }) {
    return _remoteDataSource.fetchYieldRateReport(
      modelSerial: modelSerial,
      range: range,
      model: model,
    );
  }

  @override
  Future<List<TETopErrorEntity>> fetchTopErrorCodes({
    required String modelSerial,
    required String range,
    String type = 'System',
  }) {
    return _remoteDataSource.fetchTopErrorCodes(
      modelSerial: modelSerial,
      range: range,
      type: type,
    );
  }

  @override
  Future<List<TETopErrorTrendPointEntity>> fetchTopErrorTrendByErrorCode({
    required String modelSerial,
    required String range,
    required String errorCode,
    String type = 'System',
  }) {
    return _remoteDataSource.fetchTopErrorTrendByErrorCode(
      modelSerial: modelSerial,
      range: range,
      errorCode: errorCode,
      type: type,
    );
  }

  @override
  Future<List<TETopErrorTrendPointEntity>> fetchTopErrorTrendByModelStation({
    required String range,
    required String errorCode,
    required String model,
    required String station,
  }) {
    return _remoteDataSource.fetchTopErrorTrendByModelStation(
      range: range,
      errorCode: errorCode,
      model: model,
      station: station,
    );
  }
}
