import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decor.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../pages/shop_details_page.dart';
import '../providers/shop_management_providers.dart';

class ShopsListView extends ConsumerStatefulWidget {
  const ShopsListView({super.key});

  @override
  ConsumerState<ShopsListView> createState() => _ShopsListViewState();
}

class _ShopsListViewState extends ConsumerState<ShopsListView> {
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
      ref.read(shopsManageProvider.notifier).loadMore();
    }
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => ref.read(shopsSearchProvider.notifier).set(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shops = ref.watch(shopsManageProvider);
    final status = ref.watch(shopsStatusFilterProvider);

    Widget chip(String label, bool? value) {
      final selected = status == value;

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
          onSelected: (_) =>
              ref.read(shopsStatusFilterProvider.notifier).set(value),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: TextField(
            controller: _search,
            onChanged: _onSearch,
            decoration: const InputDecoration(
              hintText: 'Поиск по названию или телефону',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              chip('Все', null),
              chip('Активные', true),
              chip('Отключённые', false),
            ],
          ),
        ),
        Expanded(
          child: shops.when(
            loading: () => const LoadingView(),
            error: (error, _) => ErrorView(
              message: errorText(error),
              onRetry: () => ref.invalidate(shopsManageProvider),
            ),
            data: (state) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(shopsManageProvider);
                await ref.read(shopsManageProvider.future);
              },
              child: state.shops.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          icon: AppIcons.store,
                          title: 'Магазинов пока нет',
                          message:
                              'Магазины появятся, когда подключатся по вашему коду.',
                        ),
                      ],
                    )
                  : ListView.separated(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      itemCount: state.shops.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == state.shops.length) {
                          return state.loadingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }

                        final shop = state.shops[index];

                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: const Icon(
                              AppIcons.store,
                              color: AppDecor.heroMid,
                            ),
                            title: Text(
                              shop.name,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text('${shop.address}\n${shop.phone}'),
                            isThreeLine: true,
                            trailing: shop.isActive
                                ? const Icon(AppIcons.forward, size: 18)
                                : const Text(
                                    'Отключён',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ShopDetailsPage(shopId: shop.id),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}