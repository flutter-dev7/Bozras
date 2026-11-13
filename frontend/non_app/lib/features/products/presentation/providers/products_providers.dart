import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:non_app/features/connections/presentation/providers/connections_providers.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/products_remote_data_source.dart';
import '../../data/repository/products_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/repository/products_repository.dart';
import '../../domain/usecases/get_products_usecase.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepositoryImpl(ProductsRemoteDataSource(ref.watch(apiClientProvider)));
});

final getProductsUseCaseProvider =
    Provider((ref) => GetProductsUseCase(ref.watch(productsRepositoryProvider)));

final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  ref.watch(currentSupplierIdProvider);

  return ref.watch(getProductsUseCaseProvider)();
});