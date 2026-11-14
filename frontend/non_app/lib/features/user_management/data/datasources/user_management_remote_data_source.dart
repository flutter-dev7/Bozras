import '../../../../core/models/paged_result.dart';
import '../../../../core/network/api_client.dart';
import '../models/staff_user_model.dart';

class UserManagementRemoteDataSource {
  UserManagementRemoteDataSource(this._client);

  final ApiClient _client;

    Future<List<StaffUserModel>> getUsers({String? role}) async {
    final path = Uri(
      path: '/api/Users',
      queryParameters: {
        if (role != null) 'Role': role,
        'Page': '1',
        'PageSize': '100',
      },
    ).toString();

    final data = await _client.get(path);

    return PagedResult.fromJson(
      data,
      StaffUserModel.fromJson,
      page: 1,
      pageSize: 100,
    ).items;
  }

  Future<void> createUser({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String role,
  }) async {
    await _client.post(
      '/api/Users',
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'role': role,
      },
    );
  }

  Future<void> updateUser(
    String id, {
    required String firstName,
    required String lastName,
    String? email,
    required String role,
    required bool isActive,
  }) async {
    await _client.put(
      '/api/Users/$id',
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': role,
        'isActive': isActive,
      },
    );
  }
}