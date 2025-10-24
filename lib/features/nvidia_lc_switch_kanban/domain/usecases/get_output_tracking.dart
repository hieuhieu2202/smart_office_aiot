import '../entities/kanban_entities.dart';
import '../repositories/nvidia_kanban_repository.dart';

class GetOutputTracking {
  GetOutputTracking(this._repository);

  final NvidiaKanbanRepository _repository;

  Future<OutputTrackingEntity> call(KanbanRequest request) {
    return _repository.fetchOutputTracking(request);
  }
}
