import '../entities/location_item.dart';
import '../repository/connections_repository.dart';

class GetLocationsUseCase {
  const GetLocationsUseCase(this._repository);

  final ConnectionsRepository _repository;

  Future<List<LocationItem>> call() => _repository.getLocations();
}