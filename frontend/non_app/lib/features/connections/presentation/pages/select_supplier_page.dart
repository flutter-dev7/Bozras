import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/connection_status.dart';
import '../providers/connections_providers.dart';
import '../widgets/my_supplier_tile.dart';

class SelectSupplierPage extends ConsumerStatefulWidget {
  const SelectSupplierPage({super.key});

  @override
  ConsumerState<SelectSupplierPage> createState() => _SelectSupplierPageState();
}

class _SelectSupplierPageState extends ConsumerState<SelectSupplierPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(mySuppliersProvider);
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(mySuppliersProvider);
    await ref.read(mySuppliersProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(mySuppliersProvider);
    final current = ref.watch(currentSupplierIdProvider);

    return Scaffold(
      appBar: AppTopBar(title: 'Поставщики', showBack: context.canPop()),
      body: suppliers.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: errorText(error),
          onRetry: () => ref.invalidate(mySuppliersProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: AppIcons.store,
              title: 'Нет поставщиков',
              message: 'Подключитесь к поставщику, чтобы делать заказы.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                for (final s in items) ...[
                  MySupplierTile(
                    supplier: s,
                    selected: s.supplierId == current,
                    onTap: s.status == ConnectionStatus.active && s.isAvailable
                        ? () async {
                            await ref
                                .read(shopGateProvider.notifier)
                                .select(s.supplierId);

                            if (context.mounted && context.canPop()) {
                              context.pop();
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.connectSupplier),
                  icon: const Icon(AppIcons.plus, size: 20),
                  label: const Text('Подключить ещё поставщика'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}