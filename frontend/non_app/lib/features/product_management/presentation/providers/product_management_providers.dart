import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:non_app/features/product_management/domain/usecases/upload_product_image_usecase.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/product_management_remote_data_source.dart';
import '../../data/repository/product_management_repository_impl.dart';
import '../../domain/entities/managed_product.dart';
import '../../domain/entities/product_category.dart';
import '../../domain/repository/product_management_repository.dart';
import '../../domain/usecases/create_category_usecase.dart';
import '../../domain/usecases/create_product_usecase.dart';
import '../../domain/usecases/delete_category_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_managed_products_usecase.dart';
import '../../domain/usecases/receive_stock_usecase.dart';
import '../../domain/usecases/rename_category_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';
import '../../domain/usecases/write_off_stock_usecase.dart';

final productManagementRepositoryProvider =
    Provider<ProductManagementRepository>((ref) {
      return ProductManagementRepositoryImpl(
        ProductManagementRemoteDataSource(ref.watch(apiClientProvider)),
      );
    });

final getManagedProductsUseCaseProvider = Provider(
  (ref) => GetManagedProductsUseCase(ref.watch(productManagementRepositoryProvider)),
);
final createProductUseCaseProvider = Provider(
  (ref) => CreateProductUseCase(ref.watch(productManagementRepositoryProvider)),
);
final updateProductUseCaseProvider = Provider(
  (ref) => UpdateProductUseCase(ref.watch(productManagementRepositoryProvider)),
);
final getCategoriesUseCaseProvider = Provider(
  (ref) => GetCategoriesUseCase(ref.watch(productManagementRepositoryProvider)),
);
final createCategoryUseCaseProvider = Provider(
  (ref) => CreateCategoryUseCase(ref.watch(productManagementRepositoryProvider)),
);
final renameCategoryUseCaseProvider = Provider(
  (ref) => RenameCategoryUseCase(ref.watch(productManagementRepositoryProvider)),
);
final deleteCategoryUseCaseProvider = Provider(
  (ref) => DeleteCategoryUseCase(ref.watch(productManagementRepositoryProvider)),
);
final receiveStockUseCaseProvider = Provider(
  (ref) => ReceiveStockUseCase(ref.watch(productManagementRepositoryProvider)),
);
final writeOffStockUseCaseProvider = Provider(
  (ref) => WriteOffStockUseCase(ref.watch(productManagementRepositoryProvider)),
);
final uploadProductImageUseCaseProvider = Provider(
  (ref) => UploadProductImageUseCase(ref.watch(productManagementRepositoryProvider)),
);

// Фильтры

final manageSearchProvider = NotifierProvider<ManageSearchNotifier, String>(
  ManageSearchNotifier.new,
);

class ManageSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final manageCategoryFilterProvider =
    NotifierProvider<ManageCategoryFilterNotifier, String?>(
      ManageCategoryFilterNotifier.new,
    );

class ManageCategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

final manageStatusFilterProvider =
    NotifierProvider<ManageStatusFilterNotifier, bool?>(
      ManageStatusFilterNotifier.new,
    );

class ManageStatusFilterNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;

  void set(bool? value) => state = value;
}

// Список с подгрузкой

class ProductsManageState {
  const ProductsManageState({
    required this.products,
    required this.page,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<ManagedProduct> products;
  final int page;
  final bool hasMore;
  final bool loadingMore;

  ProductsManageState copyWith({
    List<ManagedProduct>? products,
    int? page,
    bool? hasMore,
    bool? loadingMore,
  }) {
    return ProductsManageState(
      products: products ?? this.products,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

const int _pageSize = 20;

final productsManageProvider =
    AsyncNotifierProvider.autoDispose<ProductsManageNotifier, ProductsManageState>(
      ProductsManageNotifier.new,
    );

class ProductsManageNotifier
    extends AutoDisposeAsyncNotifier<ProductsManageState> {
  @override
  Future<ProductsManageState> build() async {
    ref.watch(currentUserIdProvider);

    final search = ref.watch(manageSearchProvider);
    final categoryId = ref.watch(manageCategoryFilterProvider);
    final isActive = ref.watch(manageStatusFilterProvider);

    final page = await ref.read(getManagedProductsUseCaseProvider)(
      search: search.trim(),
      isActive: isActive,
      categoryId: categoryId,
      page: 1,
      pageSize: _pageSize,
    );

    return ProductsManageState(
      products: page.items,
      page: 1,
      hasMore: page.hasMore,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;

    if (current == null || !current.hasMore || current.loadingMore) return;

    state = AsyncData(current.copyWith(loadingMore: true));

    try {
      final next = await ref.read(getManagedProductsUseCaseProvider)(
        search: ref.read(manageSearchProvider).trim(),
        isActive: ref.read(manageStatusFilterProvider),
        categoryId: ref.read(manageCategoryFilterProvider),
        page: current.page + 1,
        pageSize: _pageSize,
      );

      state = AsyncData(
        current.copyWith(
          products: [...current.products, ...next.items],
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

final manageCategoriesProvider =
    FutureProvider.autoDispose<List<ProductCategory>>((ref) {
      ref.watch(currentUserIdProvider);

      return ref.watch(getCategoriesUseCaseProvider)();
    });