import '../../domain/entities/kanban_entities.dart';
import '../../domain/repositories/nvidia_kanban_repository.dart';
import '../datasources/nvidia_kanban_remote_data_source.dart';
import '../models/detail_models.dart';
import '../models/output_tracking_model.dart';
import '../models/uph_tracking_model.dart';

class NvidiaKanbanRepositoryImpl implements NvidiaKanbanRepository {
  NvidiaKanbanRepositoryImpl({
    NvidiaKanbanRemoteDataSource? remoteDataSource,
  }) : _remote = remoteDataSource ?? NvidiaKanbanRemoteDataSource();

  final NvidiaKanbanRemoteDataSource _remote;

  @override
  Future<List<String>> fetchGroups(KanbanRequest request) {
    return _remote.fetchGroups(request: request);
  }

  @override
  Future<OutputTrackingEntity> fetchOutputTracking(KanbanRequest request) async {
    final OutputTrackingModel model =
        await _remote.fetchOutputTracking(request: request);
    return model;
  }

  @override
  Future<UphTrackingEntity> fetchUphTracking(KanbanRequest request) async {
    final UphTrackingModel model =
        await _remote.fetchUphTracking(request: request);
    return model;
  }

  @override
  Future<OutputTrackingDetailEntity> fetchOutputTrackingDetail(
    OutputTrackingDetailParams params,
  ) async {
    final OutputTrackingDetailModel detail =
        await _remote.fetchOutputTrackingDetail(params: params);
    return detail;
  }
}
