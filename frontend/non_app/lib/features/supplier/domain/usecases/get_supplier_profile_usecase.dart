import '../entities/supplier_profile.dart';
import '../repository/supplier_repository.dart';

class GetSupplierProfileUseCase {
  GetSupplierProfileUseCase(this._repository);

  final SupplierRepository _repository;

  Future<SupplierProfile> call() => _repository.getProfile();
}