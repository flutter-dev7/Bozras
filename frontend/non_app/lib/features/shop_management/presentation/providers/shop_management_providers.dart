import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:non_app/features/shop_management/domain/entities/shop_debt.dart';
import 'package:non_app/features/shop_management/domain/usecases/get_shop_debts_usecase.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/shop_management_remote_data_source.dart';
import '../../data/repository/shop_management_repository_impl.dart';
import '../../domain/entities/managed_shop.dart';
import '../../domain/entities/shop_balance.dart';
import '../../domain/entities/shop_payment.dart';
import '../../domain/repository/shop_management_repository.dart';
import '../../domain/usecases/create_shop_payment_usecase.dart';
import '../../domain/usecases/get_managed_shop_usecase.dart';
import '../../domain/usecases/get_managed_shops_usecase.dart';
import '../../domain/usecases/get_shop_balance_usecase.dart';
import '../../domain/usecases/get_shop_payments_usecase.dart';
import '../../domain/usecases/reverse_shop_payment_usecase.dart';
import '../../domain/usecases/set_debt_limit_usecase.dart';
import '../../domain/usecases/set_shop_owner_usecase.dart';
import '../../domain/usecases/update_managed_shop_usecase.dart';

final shopManagementRepositoryProvider = Provider<ShopManagementRepository>((
  ref,
) {
  return ShopManagementRepositoryImpl(
    ShopManagementRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

final getManagedShopsUseCaseProvider = Provider(
  (ref) => GetManagedShopsUseCase(ref.watch(shopManagementRepositoryProvider)),
);
final getManagedShopUseCaseProvider = Provider(
  (ref) => GetManagedShopUseCase(ref.watch(shopManagementRepositoryProvider)),
);
final getShopBalanceUseCaseProvider = Provider(
  (ref) => GetShopBalanceUseCase(ref.watch(shopManagementRepositoryProvider)),
);
final updateManagedShopUseCaseProvider = Provider(
  (ref) =>
      UpdateManagedShopUseCase(ref.watch(shopManagementRepositoryProvider)),
);
final setDebtLimitUseCaseProvider = Provider(
  (ref) => SetDebtLimitUseCase(ref.watch(shopManagementRepositoryProvider)),
);
final setShopOwnerUseCaseProvider = Provider(
  (ref) => SetShopOwnerUseCase(ref.watch(shopManagementRepositoryProvider)),
);
final getShopPaymentsUseCaseProvider = Provider(
  (ref) => GetShopPaymentsUseCase(ref.watch(shopManagementRepositoryProvider)),
);
final createShopPaymentUseCaseProvider = Provider(
  (ref) =>
      CreateShopPaymentUseCase(ref.watch(shopManagementRepositoryProvider)),
);
final reverseShopPaymentUseCaseProvider = Provider(
  (ref) =>
      ReverseShopPaymentUseCase(ref.watch(shopManagementRepositoryProvider)),
);

final managedShopProvider = FutureProvider.autoDispose
    .family<ManagedShop, String>((ref, id) {
      return ref.watch(getManagedShopUseCaseProvider)(id);
    });

final shopBalanceProvider = FutureProvider.autoDispose
    .family<ShopBalance, String>((ref, id) {
      return ref.watch(getShopBalanceUseCaseProvider)(id);
    });

final shopPaymentsProvider = FutureProvider.autoDispose
    .family<List<ShopPayment>, String>((ref, id) {
      return ref.watch(getShopPaymentsUseCaseProvider)(id);
    });

final getShopDebtsUseCaseProvider = Provider(
  (ref) => GetShopDebtsUseCase(ref.watch(shopManagementRepositoryProvider)),
);

final shopDebtsProvider = FutureProvider.autoDispose<List<ShopDebt>>((ref) {
  ref.watch(currentUserIdProvider);

  return ref.watch(getShopDebtsUseCaseProvider)();
});

// Фильтры списка

final shopsSearchProvider = NotifierProvider<ShopsSearchNotifier, String>(
  ShopsSearchNotifier.new,
);

class ShopsSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final shopsStatusFilterProvider =
    NotifierProvider<ShopsStatusFilterNotifier, bool?>(
      ShopsStatusFilterNotifier.new,
    );

class ShopsStatusFilterNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;

  void set(bool? value) => state = value;
}

class ShopsManageState {
  const ShopsManageState({
    required this.shops,
    required this.page,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<ManagedShop> shops;
  final int page;
  final bool hasMore;
  final bool loadingMore;

  ShopsManageState copyWith({
    List<ManagedShop>? shops,
    int? page,
    bool? hasMore,
    bool? loadingMore,
  }) {
    return ShopsManageState(
      shops: shops ?? this.shops,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

const int _pageSize = 20;

final shopsManageProvider =
    AsyncNotifierProvider.autoDispose<ShopsManageNotifier, ShopsManageState>(
      ShopsManageNotifier.new,
    );

class ShopsManageNotifier extends AutoDisposeAsyncNotifier<ShopsManageState> {
  @override
  Future<ShopsManageState> build() async {
    ref.watch(currentUserIdProvider);

    final page = await ref.read(getManagedShopsUseCaseProvider)(
      search: ref.watch(shopsSearchProvider).trim(),
      isActive: ref.watch(shopsStatusFilterProvider),
      page: 1,
      pageSize: _pageSize,
    );

    return ShopsManageState(shops: page.items, page: 1, hasMore: page.hasMore);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;

    if (current == null || !current.hasMore || current.loadingMore) return;

    state = AsyncData(current.copyWith(loadingMore: true));

    try {
      final next = await ref.read(getManagedShopsUseCaseProvider)(
        search: ref.read(shopsSearchProvider).trim(),
        isActive: ref.read(shopsStatusFilterProvider),
        page: current.page + 1,
        pageSize: _pageSize,
      );

      state = AsyncData(
        current.copyWith(
          shops: [...current.shops, ...next.items],
          page: current.page + 1,
          hasMore: next.hasMore,
          loadingMore: false,
        ),
      );
    } on ApiException {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }
}
