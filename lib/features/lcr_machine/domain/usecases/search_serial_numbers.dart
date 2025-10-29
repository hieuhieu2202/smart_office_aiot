import '../entities/lcr_entities.dart';
import '../repositories/lcr_repository.dart';

class SearchLcrSerialNumbers {
  const SearchLcrSerialNumbers(this._repository);

  final LcrRepository _repository;

  Future<List<LcrRecord>> call(String query, {int take = 12}) {
    return _repository.searchSerialNumbers(query: query, take: take);
  }
}
