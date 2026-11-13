import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/supplier_remote_data_source.dart';
import '../../data/repository/supplier_repository_impl.dart';
import '../../domain/entities/shop_request.dart';
import '../../domain/entities/supplier_profile.dart';
import '../../domain/repository/supplier_repository.dart';
import '../../domain/usecases/approve_shop_request_usecase.dart';
import '../../domain/usecases/get_shop_requests_usecase.dart';
import '../../domain/usecases/get_supplier_profile_usecase.dart';
import '../../domain/usecases/regenerate_supplier_code_usecase.dart';
import '../../domain/usecases/reject_shop_request_usecase.dart';
import '../../domain/usecases/update_supplier_profile_usecase.dart';

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  return SupplierRepositoryImpl(
    SupplierRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

final getSupplierProfileUseCaseProvider = Provider(
  (ref) => GetSupplierProfileUseCase(ref.watch(supplierRepositoryProvider)),
);
final updateSupplierProfileUseCaseProvider = Provider(
  (ref) => UpdateSupplierProfileUseCase(ref.watch(supplierRepositoryProvider)),
);
final regenerateSupplierCodeUseCaseProvider = Provider(
  (ref) => RegenerateSupplierCodeUseCase(ref.watch(supplierRepositoryProvider)),
);
final getShopRequestsUseCaseProvider = Provider(
  (ref) => GetShopRequestsUseCase(ref.watch(supplierRepositoryProvider)),
);
final approveShopRequestUseCaseProvider = Provider(
  (ref) => ApproveShopRequestUseCase(ref.watch(supplierRepositoryProvider)),
);
final rejectShopRequestUseCaseProvider = Provider(
  (ref) => RejectShopRequestUseCase(ref.watch(supplierRepositoryProvider)),
);

final supplierProfileProvider = FutureProvider.autoDispose<SupplierProfile>((
  ref,
) {
  ref.watch(currentUserIdProvider);

  return ref.watch(getSupplierProfileUseCaseProvider)();
});

final shopRequestsProvider = FutureProvider.autoDispose<List<ShopRequest>>((
  ref,
) {
  ref.watch(currentUserIdProvider);

  return ref.watch(getShopRequestsUseCaseProvider)();
});