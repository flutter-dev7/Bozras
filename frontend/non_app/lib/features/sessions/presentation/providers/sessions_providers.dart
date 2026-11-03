import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/sessions_remote_data_source.dart';
import '../../data/repository/sessions_repository_impl.dart';
import '../../domain/entities/device_session.dart';
import '../../domain/repository/sessions_repository.dart';
import '../../domain/usecases/get_sessions_usecase.dart';
import '../../domain/usecases/revoke_session_usecase.dart';

final sessionsRepositoryProvider = Provider<SessionsRepository>((ref) {
  return SessionsRepositoryImpl(SessionsRemoteDataSource(ref.watch(apiClientProvider)));
});

final getSessionsUseCaseProvider =
    Provider((ref) => GetSessionsUseCase(ref.watch(sessionsRepositoryProvider)));
final revokeSessionUseCaseProvider =
    Provider((ref) => RevokeSessionUseCase(ref.watch(sessionsRepositoryProvider)));

final sessionsProvider = FutureProvider.autoDispose<List<DeviceSession>>((ref) {
  return ref.watch(getSessionsUseCaseProvider)();
});