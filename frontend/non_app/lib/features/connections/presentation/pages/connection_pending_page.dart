import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/connections_providers.dart';

class ConnectionPendingPage extends ConsumerStatefulWidget {
  const ConnectionPendingPage({super.key});

  @override
  ConsumerState<ConnectionPendingPage> createState() => _ConnectionPendingPageState();
}

class _ConnectionPendingPageState extends ConsumerState<ConnectionPendingPage> {
  bool _loading = false;

  Future<void> _refresh() async {
    setState(() => _loading = true);

    try {
      await ref.read(shopGateProvider.notifier).reload();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Заявка отправлена', showBack: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              const Expanded(
                child: EmptyState(
                  icon: AppIcons.clock,
                  title: 'Ждём подтверждения',
                  message:
                      'Поставщик должен принять вашу заявку. Каталог откроется, как только это произойдёт.',
                ),
              ),
              PrimaryButton(label: 'Обновить', onPressed: _refresh, isLoading: _loading),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push(AppRoutes.connectSupplier),
                child: const Text('Подключиться к другому'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}