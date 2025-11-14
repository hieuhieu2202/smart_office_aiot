import '../../domain/entities/station_overview_entities.dart';
import '../../domain/repositories/station_overview_repository.dart';
import '../datasources/station_overview_remote_data_source.dart';

class StationOverviewRepositoryImpl implements StationOverviewRepository {
  StationOverviewRepositoryImpl({
    StationOverviewRemoteDataSource? remoteDataSource,
  }) : _remote = remoteDataSource ?? StationOverviewRemoteDataSource();

  final StationOverviewRemoteDataSource _remote;

  @override
  Future<List<StationProduct>> getProducts({required String modelSerial}) {
    return _remote.fetchProducts(modelSerial: modelSerial);
  }

  @override
  Future<List<StationOverviewData>> getOverview(
    StationOverviewFilter filter,
  ) {
    return _remote.fetchOverview(filter: filter);
  }

  @override
  Future<List<StationAnalysisData>> getStationAnalysis(
    StationOverviewFilter filter,
  ) {
    return _remote.fetchStationAnalysis(filter: filter);
  }

  @override
  Future<List<StationDetailData>> getStationDetails(
    StationOverviewFilter filter,
  ) {
    return _remote.fetchStationDetails(filter: filter);
  }
}
