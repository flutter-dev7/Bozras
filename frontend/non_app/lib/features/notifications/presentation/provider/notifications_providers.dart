import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/devices_remote_data_source.dart';
import '../../data/repository/devices_repository_impl.dart';
import '../../data/services/push_service.dart';
import '../../domain/repository/devices_repository.dart';
import '../../domain/usecases/delete_fcm_token_usecase.dart';
import '../../domain/usecases/save_fcm_token_usecase.dart';

final devicesRepositoryProvider = Provider<DevicesRepository>((ref) {
  return DevicesRepositoryImpl(DevicesRemoteDataSource(ref.watch(apiClientProvider)));
});

final saveFcmTokenUseCaseProvider =
    Provider((ref) => SaveFcmTokenUseCase(ref.watch(devicesRepositoryProvider)));
final deleteFcmTokenUseCaseProvider =
    Provider((ref) => DeleteFcmTokenUseCase(ref.watch(devicesRepositoryProvider)));

final pushServiceProvider = Provider<PushService>((ref) {
  return PushService(
    saveToken: ref.watch(saveFcmTokenUseCaseProvider),
    deleteToken: ref.watch(deleteFcmTokenUseCaseProvider),
  );
});