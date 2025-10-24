import '../entities/kanban_entities.dart';
import '../repositories/nvidia_kanban_repository.dart';

class GetOutputTrackingDetail {
  GetOutputTrackingDetail(this._repository);

  final NvidiaKanbanRepository _repository;

  Future<OutputTrackingDetailEntity> call(
    OutputTrackingDetailParams params,
  ) {
    return _repository.fetchOutputTrackingDetail(params);
  }
}
