import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:non_app/features/auth/domain/entities/user_role.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/connections_remote_data_source.dart';
import '../../data/repository/connections_repository_impl.dart';
import '../../domain/entities/connection_status.dart';
import '../../domain/entities/location_item.dart';
import '../../domain/entities/my_supplier.dart';
import '../../domain/entities/shop_profile.dart';
import '../../domain/entities/supplier_card.dart';
import '../../domain/repository/connections_repository.dart';
import '../../domain/usecases/connect_by_code_usecase.dart';
import '../../domain/usecases/connect_to_supplier_usecase.dart';
import '../../domain/usecases/get_locations_usecase.dart';
import '../../domain/usecases/get_my_suppliers_usecase.dart';
import '../../domain/usecases/get_nearby_suppliers_usecase.dart';
import '../../domain/usecases/get_shop_profile_usecase.dart';
import '../../domain/usecases/save_shop_profile_usecase.dart';

final connectionsRepositoryProvider = Provider<ConnectionsRepository>((ref) {
  return ConnectionsRepositoryImpl(
    ConnectionsRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

final getShopProfileUseCaseProvider =
    Provider((ref) => GetShopProfileUseCase(ref.watch(connectionsRepositoryProvider)));
final saveShopProfileUseCaseProvider =
    Provider((ref) => SaveShopProfileUseCase(ref.watch(connectionsRepositoryProvider)));
final getNearbySuppliersUseCaseProvider =
    Provider((ref) => GetNearbySuppliersUseCase(ref.watch(connectionsRepositoryProvider)));
final getMySuppliersUseCaseProvider =
    Provider((ref) => GetMySuppliersUseCase(ref.watch(connectionsRepositoryProvider)));
final connectByCodeUseCaseProvider =
    Provider((ref) => ConnectByCodeUseCase(ref.watch(connectionsRepositoryProvider)));
final connectToSupplierUseCaseProvider =
    Provider((ref) => ConnectToSupplierUseCase(ref.watch(connectionsRepositoryProvider)));
final getLocationsUseCaseProvider =
    Provider((ref) => GetLocationsUseCase(ref.watch(connectionsRepositoryProvider)));

final shopProfileProvider = FutureProvider<ShopProfile?>((ref) {
  ref.watch(currentUserIdProvider);

  return ref.read(getShopProfileUseCaseProvider)();
});

final mySuppliersProvider = FutureProvider<List<MySupplier>>((ref) {
  ref.watch(currentUserIdProvider);

  return ref.read(getMySuppliersUseCaseProvider)();
});

final nearbySuppliersProvider =
    FutureProvider.autoDispose.family<List<SupplierCard>, String>((ref, search) {
  return ref.read(getNearbySuppliersUseCaseProvider)(search.trim());
});

final locationsProvider = FutureProvider<List<LocationItem>>((ref) {
  return ref.read(getLocationsUseCaseProvider)();
});

enum ShopStage { needsProfile, needsConnection, pending, needsSelection, ready }

class ShopGateState {
  const ShopGateState(this.stage, {this.supplierId});

  final ShopStage stage;
  final String? supplierId;
}

final shopGateProvider =
    AsyncNotifierProvider<ShopGateNotifier, ShopGateState>(ShopGateNotifier.new);

class ShopGateNotifier extends AsyncNotifier<ShopGateState> {
  @override
  Future<ShopGateState> build() async {
    final userId = ref.watch(currentUserIdProvider)?.toString();
    final storage = ref.read(supplierStorageProvider);

    if (userId == null) {
      await storage.clear();
      return const ShopGateState(ShopStage.needsProfile);
    }

    final profile = await ref.read(getShopProfileUseCaseProvider)();

    if (profile == null) {
      await storage.clear();
      return const ShopGateState(ShopStage.needsProfile);
    }

    final suppliers = await ref.read(getMySuppliersUseCaseProvider)();
    final active = suppliers.where((s) => s.status == ConnectionStatus.active).toList();
    final usable = active.where((s) => s.isAvailable).toList();

    final stored = await storage.load(userId);

    if (stored != null && usable.any((s) => s.supplierId == stored)) {
      return ShopGateState(ShopStage.ready, supplierId: stored);
    }

    if (usable.length == 1) {
      final id = usable.first.supplierId;
      await storage.save(userId, id);

      return ShopGateState(ShopStage.ready, supplierId: id);
    }

    await storage.clear();

    if (active.isNotEmpty) return const ShopGateState(ShopStage.needsSelection);

    if (suppliers.any((s) => s.status == ConnectionStatus.pending)) {
      return const ShopGateState(ShopStage.pending);
    }

    return const ShopGateState(ShopStage.needsConnection);
  }

  Future<void> select(String supplierId) async {
    final userId = ref.read(currentUserIdProvider)?.toString();

    if (userId == null) return;

    await ref.read(supplierStorageProvider).save(userId, supplierId);

    state = AsyncData(ShopGateState(ShopStage.ready, supplierId: supplierId));
  }

  Future<void> reload() async {
    ref.invalidate(mySuppliersProvider);
    ref.invalidate(shopProfileProvider);
    ref.invalidateSelf();

    await future;
  }
}

final currentSupplierIdProvider = Provider<String?>((ref) {
  final user = ref.watch(authProvider).valueOrNull;

  if (user?.role != UserRole.shop) return null;

  return ref.watch(shopGateProvider).valueOrNull?.supplierId;
});