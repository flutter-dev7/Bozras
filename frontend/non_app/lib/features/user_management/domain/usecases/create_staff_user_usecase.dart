import '../repository/user_management_repository.dart';

class CreateStaffUserUseCase {
  CreateStaffUserUseCase(this._repository);

  final UserManagementRepository _repository;

  Future<void> call({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String role,
  }) => _repository.createUser(
    firstName: firstName,
    lastName: lastName,
    phone: phone,
    email: email,
    role: role,
  );
}