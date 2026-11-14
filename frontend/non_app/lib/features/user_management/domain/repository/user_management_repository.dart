import '../entities/staff_user.dart';

abstract class UserManagementRepository {
  Future<List<StaffUser>> getUsers({String? role});

  Future<void> createUser({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String role,
  });

  Future<void> updateUser(
    String id, {
    required String firstName,
    required String lastName,
    String? email,
    required String role,
    required bool isActive,
  });
}