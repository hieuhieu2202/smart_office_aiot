import '../../domain/entities/lcr_entities.dart';
import '../../domain/repositories/lcr_repository.dart';
import '../datasources/lcr_remote_data_source.dart';

class LcrRepositoryImpl implements LcrRepository {
  LcrRepositoryImpl({LcrRemoteDataSource? remoteDataSource})
      : _remote = remoteDataSource ?? LcrRemoteDataSource();

  final LcrRemoteDataSource _remote;

  @override
  Future<List<LcrFactory>> fetchLocations() {
    return _remote.fetchLocations();
  }

  @override
  Future<List<LcrRecord>> fetchTrackingData({required LcrRequest request}) {
    return _remote.fetchTrackingData(request: request);
  }

  @override
  Future<List<LcrRecord>> fetchAnalysisData({required LcrRequest request}) {
    return _remote.fetchAnalysisData(request: request);
  }

  @override
  Future<List<LcrRecord>> searchSerialNumbers({
    required String query,
    int take = 12,
  }) {
    return _remote.searchSerialNumbers(query: query, take: take);
  }

  @override
  Future<LcrRecord?> fetchRecord({required int id}) {
    return _remote.fetchRecord(id: id);
  }
}
