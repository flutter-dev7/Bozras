import '../../domain/entities/staff_user.dart';
import '../../domain/repository/user_management_repository.dart';
import '../datasources/user_management_remote_data_source.dart';

class UserManagementRepositoryImpl implements UserManagementRepository {
  UserManagementRepositoryImpl(this._remote);

  final UserManagementRemoteDataSource _remote;

  @override
  Future<List<StaffUser>> getUsers({String? role}) =>
      _remote.getUsers(role: role);

  @override
  Future<void> createUser({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String role,
  }) => _remote.createUser(
    firstName: firstName,
    lastName: lastName,
    phone: phone,
    email: email,
    role: role,
  );

  @override
  Future<void> updateUser(
    String id, {
    required String firstName,
    required String lastName,
    String? email,
    required String role,
    required bool isActive,
  }) => _remote.updateUser(
    id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    role: role,
    isActive: isActive,
  );
}