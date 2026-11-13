import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decor.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../pages/shop_details_page.dart';
import '../providers/shop_management_providers.dart';

class DebtsView extends ConsumerWidget {
  const DebtsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debts = ref.watch(shopDebtsProvider);

    return debts.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        message: errorText(error),
        onRetry: () => ref.invalidate(shopDebtsProvider),
      ),
      data: (items) {
        final total = items.fold<double>(0, (sum, d) => sum + d.debt);
        final overLimit = items.where((d) => d.isOverLimit).length;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(shopDebtsProvider);
            await ref.read(shopDebtsProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: 'Общий долг',
                      value: Formatters.money(total),
                      color: total > 0 ? AppColors.error : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Stat(label: 'Должников', value: '${items.length}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Stat(
                      label: 'Сверх лимита',
                      value: '$overLimit',
                      color: overLimit > 0 ? AppColors.error : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: EmptyState(
                    icon: AppIcons.wallet,
                    title: 'Долгов нет',
                    message: 'Все магазины рассчитались.',
                  ),
                )
              else
                for (final debt in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ShopDetailsPage(shopId: debt.shopId),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          debt.shopName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          debt.shopPhone,
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    Formatters.money(debt.debt),
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              if (debt.isOverLimit) ...[
                                const SizedBox(height: 6),
                                const Text(
                                  'Превышен лимит',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                              if (debt.debtLimit != null &&
                                  debt.debtLimit! > 0) ...[
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: (debt.debt / debt.debtLimit!).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    minHeight: 8,
                                    backgroundColor: AppDecor.fieldFill,
                                    color: debt.isOverLimit
                                        ? AppColors.error
                                        : AppDecor.heroMid,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Лимит ${Formatters.money(debt.debtLimit!)}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}