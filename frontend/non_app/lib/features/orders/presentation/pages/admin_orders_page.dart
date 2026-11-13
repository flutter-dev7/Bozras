import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:non_app/features/notifications/presentation/widgets/notifications_bell.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../providers/orders_providers.dart';
import '../widgets/order_card.dart';
import '../widgets/order_status_filter.dart';

class AdminOrdersPage extends ConsumerStatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  ConsumerState<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends ConsumerState<AdminOrdersPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
      ref.read(ordersProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: const AppTopBar(
        title: 'Все заказы',
        showBack: false,
        actions: [NotificationsBell()],
      ),
      body: orders.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: errorText(error),
          onRetry: () => ref.invalidate(ordersProvider),
        ),
        data: (state) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ordersProvider);
            await ref.read(ordersProvider.future);
          },
          child: ListView.builder(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: state.orders.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 16),
                  child: OrderStatusFilter(),
                );
              }

              if (index == state.orders.length + 1) {
                if (state.orders.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: EmptyState(
                      icon: AppIcons.receipt,
                      title: 'Заказов пока нет',
                      message: 'Здесь появятся заказы ваших магазинов.',
                    ),
                  );
                }

                return state.loadingMore
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox(height: 8);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OrderCard(
                  order: state.orders[index - 1],
                  showShop: true,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}