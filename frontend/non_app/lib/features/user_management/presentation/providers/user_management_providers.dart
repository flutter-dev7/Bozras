import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/user_management_remote_data_source.dart';
import '../../data/repository/user_management_repository_impl.dart';
import '../../domain/entities/staff_user.dart';
import '../../domain/repository/user_management_repository.dart';
import '../../domain/usecases/create_staff_user_usecase.dart';
import '../../domain/usecases/get_staff_users_usecase.dart';
import '../../domain/usecases/update_staff_user_usecase.dart';

final userManagementRepositoryProvider = Provider<UserManagementRepository>((
  ref,
) {
  return UserManagementRepositoryImpl(
    UserManagementRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

final getStaffUsersUseCaseProvider = Provider(
  (ref) => GetStaffUsersUseCase(ref.watch(userManagementRepositoryProvider)),
);
final createStaffUserUseCaseProvider = Provider(
  (ref) => CreateStaffUserUseCase(ref.watch(userManagementRepositoryProvider)),
);
final updateStaffUserUseCaseProvider = Provider(
  (ref) => UpdateStaffUserUseCase(ref.watch(userManagementRepositoryProvider)),
);

final staffUsersProvider = FutureProvider.autoDispose
    .family<List<StaffUser>, String?>((ref, role) {
      ref.watch(currentUserIdProvider);

      return ref.watch(getStaffUsersUseCaseProvider)(role: role);
    });