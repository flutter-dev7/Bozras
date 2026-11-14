import '../repository/user_management_repository.dart';

class UpdateStaffUserUseCase {
  UpdateStaffUserUseCase(this._repository);

  final UserManagementRepository _repository;

  Future<void> call(
    String id, {
    required String firstName,
    required String lastName,
    String? email,
    required String role,
    required bool isActive,
  }) => _repository.updateUser(
    id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    role: role,
    isActive: isActive,
  );
}