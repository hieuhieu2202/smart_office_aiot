import '../entities/lcr_entities.dart';

abstract class LcrRepository {
  Future<List<LcrFactory>> fetchLocations();
  Future<List<LcrRecord>> fetchTrackingData({required LcrRequest request});
  Future<List<LcrRecord>> fetchAnalysisData({required LcrRequest request});
  Future<List<LcrRecord>> searchSerialNumbers({
    required String query,
    int take,
  });
  Future<LcrRecord?> fetchRecord({required int id});
}
