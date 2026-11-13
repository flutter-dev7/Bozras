import '../repository/supplier_repository.dart';

class UpdateSupplierProfileUseCase {
  UpdateSupplierProfileUseCase(this._repository);

  final SupplierRepository _repository;

  Future<void> call({
    String? phone,
    String? description,
    required bool requiresApproval,
  }) => _repository.updateProfile(
    phone: phone,
    description: description,
    requiresApproval: requiresApproval,
  );
}