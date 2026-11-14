import '../entities/staff_user.dart';
import '../repository/user_management_repository.dart';

class GetStaffUsersUseCase {
  GetStaffUsersUseCase(this._repository);

  final UserManagementRepository _repository;

  Future<List<StaffUser>> call({String? role}) =>
      _repository.getUsers(role: role);
}