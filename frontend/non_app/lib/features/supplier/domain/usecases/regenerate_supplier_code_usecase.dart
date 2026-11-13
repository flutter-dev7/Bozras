import '../entities/supplier_profile.dart';
import '../repository/supplier_repository.dart';

class RegenerateSupplierCodeUseCase {
  RegenerateSupplierCodeUseCase(this._repository);

  final SupplierRepository _repository;

  Future<SupplierProfile> call() => _repository.regenerateCode();
}