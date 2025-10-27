import '../../domain/entities/te_report.dart';
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
}
