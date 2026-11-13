import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decor.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/managed_product.dart';
import '../providers/product_management_providers.dart';
import '../widgets/categories_sheet.dart';
import '../widgets/stock_dialog.dart';
import 'product_form_page.dart';

class ProductsManagePage extends ConsumerStatefulWidget {
  const ProductsManagePage({super.key});

  @override
  ConsumerState<ProductsManagePage> createState() => _ProductsManagePageState();
}

class _ProductsManagePageState extends ConsumerState<ProductsManagePage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
      ref.read(productsManageProvider.notifier).loadMore();
    }
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => ref.read(manageSearchProvider.notifier).set(value),
    );
  }

  Future<void> _openForm([ManagedProduct? product]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProductFormPage(product: product)),
    );

    if (saved == true) ref.invalidate(productsManageProvider);
  }

  void _openCategories() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => const CategoriesSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsManageProvider);
    final status = ref.watch(manageStatusFilterProvider);
    final categoryId = ref.watch(manageCategoryFilterProvider);
    final categories = ref.watch(manageCategoriesProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppTopBar(
        title: 'Товары',
        showBack: false,
        actions: [
          AppIconButton(
            icon: Icons.sell_outlined,
            tooltip: 'Категории',
            onPressed: _openCategories,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: AppDecor.heroMid,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(AppIcons.plus),
        label: const Text(
          'Добавить',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              controller: _search,
              onChanged: _onSearch,
              decoration: const InputDecoration(
                hintText: 'Поиск по названию',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterChip(
                  label: 'Все',
                  selected: status == null,
                  onTap: () =>
                      ref.read(manageStatusFilterProvider.notifier).set(null),
                ),
                _FilterChip(
                  label: 'В продаже',
                  selected: status == true,
                  onTap: () =>
                      ref.read(manageStatusFilterProvider.notifier).set(true),
                ),
                _FilterChip(
                  label: 'Скрытые',
                  selected: status == false,
                  onTap: () =>
                      ref.read(manageStatusFilterProvider.notifier).set(false),
                ),
                if (categories.isNotEmpty) const SizedBox(width: 8),
                for (final category in categories)
                  _FilterChip(
                    label: category.name,
                    selected: categoryId == category.id,
                    onTap: () => ref
                        .read(manageCategoryFilterProvider.notifier)
                        .set(categoryId == category.id ? null : category.id),
                  ),
              ],
            ),
          ),
          Expanded(
            child: products.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                message: errorText(error),
                onRetry: () => ref.invalidate(productsManageProvider),
              ),
              data: (state) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(productsManageProvider);
                  await ref.read(productsManageProvider.future);
                },
                child: state.products.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 80),
                          EmptyState(
                            icon: AppIcons.store,
                            title: 'Товары не найдены',
                            message: 'Нажмите «Добавить», чтобы создать товар.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                        itemCount: state.products.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == state.products.length) {
                            return state.loadingMore
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          }

                          final product = state.products[index];

                          return _ProductTile(
                            product: product,
                            onTap: () => _openForm(product),
                            onStock: () => showStockDialog(context, product),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppDecor.heroMid,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.brown,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.onTap,
    required this.onStock,
  });

  final ManagedProduct product;
  final VoidCallback onTap;
  final VoidCallback onStock;

  @override
  Widget build(BuildContext context) {
    final stock = product.stockQuantity;
    final stockColor = stock <= 0
        ? AppColors.error
        : stock <= 10
        ? Colors.orange.shade800
        : AppColors.brown;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        product.categoryName ?? 'Без категории',
                        if (product.weightInGrams != null)
                          '${product.weightInGrams} г',
                      ].join(' · '),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${Formatters.money(product.price)} / ${product.unit}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          stock <= 0 ? 'Нет' : '$stock ${product.unit}',
                          style: TextStyle(
                            color: stockColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (!product.isActive) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Скрыт от магазинов',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              AppIconButton(
                icon: Icons.inventory_2_outlined,
                tooltip: 'Приход и списание',
                onPressed: onStock,
              ),
            ],
          ),
        ),
      ),
    );
  }
}