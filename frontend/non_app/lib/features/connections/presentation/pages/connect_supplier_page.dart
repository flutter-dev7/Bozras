import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/connection_status.dart';
import '../../domain/entities/supplier_card.dart';
import '../providers/connections_providers.dart';
import '../widgets/supplier_card_tile.dart';

class ConnectSupplierPage extends ConsumerStatefulWidget {
  const ConnectSupplierPage({super.key});

  @override
  ConsumerState<ConnectSupplierPage> createState() => _ConnectSupplierPageState();
}

class _ConnectSupplierPageState extends ConsumerState<ConnectSupplierPage> {
  final _code = TextEditingController();
  Timer? _debounce;
  String _search = '';
  bool _busy = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _search = value.trim());
    });
  }

  Future<void> _run(Future<SupplierCard> Function() action) async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final card = await action();

      ref.invalidate(nearbySuppliersProvider);
      await ref.read(shopGateProvider.notifier).reload();

      if (!mounted) return;

      AppSnackBar.show(
        context,
        card.status == ConnectionStatus.pending
            ? 'Заявка отправлена, ждите подтверждения'
            : 'Вы подключены к «${card.name}»',
      );

      if (context.canPop()) context.pop();
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.show(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _connectByCode() {
    final code = _code.text.trim();

    if (code.isEmpty) {
      AppSnackBar.show(context, 'Введите код поставщика', isError: true);
      return;
    }

    _run(() => ref.read(connectByCodeUseCaseProvider)(code));
  }

  @override
  Widget build(BuildContext context) {
    final nearby = ref.watch(nearbySuppliersProvider(_search));

    return Scaffold(
      appBar: AppTopBar(title: 'Подключение к поставщику', showBack: context.canPop()),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Text(
              'Код поставщика',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Если поставщик дал вам код, введите его здесь.',
              style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _code,
              label: 'Код',
              hint: 'Например, L5NM4W',
              icon: AppIcons.key,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                TextInputFormatter.withFunction(
                  (old, value) => value.copyWith(text: value.text.toUpperCase()),
                ),
              ],
              onSubmitted: (_) => _connectByCode(),
              enabled: !_busy,
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Подключиться',
              onPressed: _connectByCode,
              isLoading: _busy,
            ),
            const SizedBox(height: 28),
            const Text(
              'Поставщики рядом',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: _onSearch,
              decoration: const InputDecoration(
                hintText: 'Поиск по названию',
                prefixIcon: Icon(AppIcons.search, size: 22),
              ),
            ),
            const SizedBox(height: 12),
            nearby.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: LoadingView(),
              ),
              error: (error, _) => ErrorView(
                message: errorText(error),
                onRetry: () => ref.invalidate(nearbySuppliersProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: AppIcons.store,
                    title: 'Поставщиков рядом нет',
                    message: 'Подключитесь по коду или измените регион в профиле.',
                  );
                }

                return Column(
                  children: [
                    for (final supplier in items) ...[
                      SupplierCardTile(
                        supplier: supplier,
                        busy: _busy,
                        onConnect: () => _run(
                          () => ref.read(connectToSupplierUseCaseProvider)(supplier.id),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}