import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:non_app/core/widgets/app_dialogs.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decor.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../shop_management/presentation/providers/shop_management_providers.dart';
import '../../domain/entities/shop_request.dart';
import '../providers/supplier_providers.dart';

class RequestsView extends ConsumerWidget {
  const RequestsView({super.key});

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref, {
    required String message,
    required Future<void> Function() action,
  }) async {
    try {
      await action();

      ref.invalidate(shopRequestsProvider);
      ref.invalidate(shopsManageProvider);

      if (context.mounted) AppSnackBar.show(context, message);
    } on ApiException catch (e) {
      if (context.mounted) {
        AppSnackBar.show(context, e.message, isError: true);
      }
    }
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    ShopRequest request,
  ) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Отклонить заявку?',
      message: 'Магазин «${request.name}» не будет подключён.',
      confirmLabel: 'Отклонить',
      destructive: true,
    );

    if (!confirmed || !context.mounted) return;

    await _decide(
      context,
      ref,
      message: 'Заявка отклонена',
      action: () => ref.read(rejectShopRequestUseCaseProvider)(request.id),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(shopRequestsProvider);

    return requests.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        message: errorText(error),
        onRetry: () => ref.invalidate(shopRequestsProvider),
      ),
      data: (items) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(shopRequestsProvider);
          await ref.read(shopRequestsProvider.future);
        },
        child: items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: AppIcons.store,
                    title: 'Заявок нет',
                    message:
                        'Здесь появятся магазины, которые хотят подключиться к вам.',
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final request = items[index];

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            request.address,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.phone,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (request.contactName != null) ...[
                            const SizedBox(height: 4),
                            Text('Контакт: ${request.contactName}'),
                          ],
                          if (request.ownerName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Владелец: ${request.ownerName}'
                              '${request.ownerPhone != null ? ' · ${request.ownerPhone}' : ''}',
                            ),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                  ),
                                  onPressed: () =>
                                      _reject(context, ref, request),
                                  child: const Text('Отклонить'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppDecor.heroMid,
                                  ),
                                  onPressed: () => _decide(
                                    context,
                                    ref,
                                    message: 'Магазин подключён',
                                    action: () => ref.read(
                                      approveShopRequestUseCaseProvider,
                                    )(request.id),
                                  ),
                                  child: const Text('Принять'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}