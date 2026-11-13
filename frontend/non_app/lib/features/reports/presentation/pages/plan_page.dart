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
import '../providers/reports_providers.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'План и отчёты', showBack: false),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppDecor.heroMid,
                  selectedForegroundColor: Colors.white,
                  foregroundColor: AppColors.brown,
                  minimumSize: const Size.fromHeight(44),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
                segments: const [
                  ButtonSegment(value: 0, label: Text('План на день')),
                  ButtonSegment(value: 1, label: Text('Продажи')),
                ],
                selected: {_tab},
                onSelectionChanged: (value) =>
                    setState(() => _tab = value.first),
              ),
            ),
          ),
          Expanded(
            child: _tab == 0 ? const _ProductionTab() : const _SalesTab(),
          ),
        ],
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppDecor.heroMid,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : AppColors.brown,
      ),
      onSelected: (_) => onTap(),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: AppDecor.fieldFill,
        color: AppDecor.heroMid,
      ),
    );
  }
}

class _ProductionTab extends ConsumerWidget {
  const _ProductionTab();

  Future<void> _pick(BuildContext context, WidgetRef ref, DateTime current) async {
    final today = Formatters.today();

    final result = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 1, today.month, today.day),
    );

    if (result != null) {
      ref.read(productionDateProvider.notifier).select(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(productionDateProvider);
    final report = ref.watch(productionProvider);
    final today = Formatters.today();
    final tomorrow = DateTime(today.year, today.month, today.day + 1);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(productionProvider);
        await ref.read(productionProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Chip(
                label: 'Сегодня',
                selected: _sameDay(date, today),
                onTap: () =>
                    ref.read(productionDateProvider.notifier).select(today),
              ),
              _Chip(
                label: 'Завтра',
                selected: _sameDay(date, tomorrow),
                onTap: () =>
                    ref.read(productionDateProvider.notifier).select(tomorrow),
              ),
              ActionChip(
                avatar: const Icon(AppIcons.calendar, size: 18),
                label: Text(Formatters.date(date)),
                onPressed: () => _pick(context, ref, date),
              ),
            ],
          ),
          const SizedBox(height: 16),
          report.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 64),
              child: LoadingView(),
            ),
            error: (error, _) => ErrorView(
              message: errorText(error),
              onRetry: () => ref.invalidate(productionProvider),
            ),
            data: (data) {
              final max = data.items.fold<int>(
                1,
                (m, item) => item.quantity > m ? item.quantity : m,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          label: 'Заказов на дату',
                          value: '${data.ordersCount}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Stat(
                          label: 'Всего испечь, шт.',
                          value: '${data.totalQuantity}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Что печь',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  if (data.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: EmptyState(
                        icon: AppIcons.receipt,
                        title: 'На эту дату заказов нет',
                        message: 'Выберите другой день.',
                      ),
                    )
                  else
                    for (final item in data.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity} шт.',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _Bar(value: item.quantity / max),
                              ],
                            ),
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SalesTab extends ConsumerWidget {
  const _SalesTab();

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    DateTimeRange current,
  ) async {
    final today = Formatters.today();

    final result = await showDateRangePicker(
      context: context,
      initialDateRange: current,
      firstDate: DateTime(today.year - 2),
      lastDate: DateTime(today.year, today.month, today.day),
    );

    if (result != null) {
      ref.read(salesRangeProvider.notifier).select(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(salesRangeProvider);
    final report = ref.watch(salesProvider);
    final today = Formatters.today();
    final todayDate = DateTime(today.year, today.month, today.day);

    final week = DateTimeRange(
      start: DateTime(today.year, today.month, today.day - 6),
      end: todayDate,
    );
    final month = currentMonthRange();
    final prevMonth = DateTimeRange(
      start: DateTime(today.year, today.month - 1, 1),
      end: DateTime(today.year, today.month, 0),
    );

    bool isRange(DateTimeRange r) =>
        _sameDay(r.start, range.start) && _sameDay(r.end, range.end);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(salesProvider);
        await ref.read(salesProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Chip(
                label: '7 дней',
                selected: isRange(week),
                onTap: () => ref.read(salesRangeProvider.notifier).select(week),
              ),
              _Chip(
                label: 'Этот месяц',
                selected: isRange(month),
                onTap: () => ref.read(salesRangeProvider.notifier).select(month),
              ),
              _Chip(
                label: 'Прошлый месяц',
                selected: isRange(prevMonth),
                onTap: () =>
                    ref.read(salesRangeProvider.notifier).select(prevMonth),
              ),
              ActionChip(
                avatar: const Icon(AppIcons.calendar, size: 18),
                label: Text(
                  '${Formatters.date(range.start)} — ${Formatters.date(range.end)}',
                ),
                onPressed: () => _pick(context, ref, range),
              ),
            ],
          ),
          const SizedBox(height: 16),
          report.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 64),
              child: LoadingView(),
            ),
            error: (error, _) => ErrorView(
              message: errorText(error),
              onRetry: () => ref.invalidate(salesProvider),
            ),
            data: (data) {
              if (data.ordersCount == 0) {
                return const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: EmptyState(
                    icon: AppIcons.receipt,
                    title: 'За этот период заказов нет',
                    message: 'Выберите другой период.',
                  ),
                );
              }

              final days = data.byDay.where((d) => d.ordersCount > 0).toList();
              final maxDay = days.fold<double>(
                1,
                (m, d) => d.amount > m ? d.amount : m,
              );
              final productsTotal = data.byProduct.fold<double>(
                0,
                (sum, p) => sum + p.amount,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.1,
                    children: [
                      _Stat(label: 'Заказов', value: '${data.ordersCount}'),
                      _Stat(
                        label: 'Сумма заказов',
                        value: Formatters.money(data.totalAmount),
                      ),
                      _Stat(
                        label: 'Продано, шт.',
                        value: '${data.totalQuantity}',
                      ),
                      _Stat(
                        label: 'Получено оплат',
                        value: Formatters.money(data.receivedPayments),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'По товарам',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  for (final product in data.byProduct)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.productName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '${product.quantity} шт.',
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    Formatters.money(product.amount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _Bar(
                                value: productsTotal > 0
                                    ? product.amount / productsTotal
                                    : 0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'По дням',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  for (final day in days)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${Formatters.date(day.date)} · ${day.ordersCount} зак.',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    Formatters.money(day.amount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _Bar(value: day.amount / maxDay),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}