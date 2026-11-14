import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:non_app/features/user_management/presentation/pages/users_manage_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decor.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../home/presentation/providers/home_navigation_provider.dart';
import '../../../supplier/presentation/providers/supplier_providers.dart';
import '../../../supplier/presentation/widgets/requests_view.dart';
import '../widgets/debts_view.dart';
import '../widgets/shops_list_view.dart';

class ShopsManagePage extends ConsumerStatefulWidget {
  const ShopsManagePage({super.key});

  @override
  ConsumerState<ShopsManagePage> createState() => _ShopsManagePageState();
}

class _ShopsManagePageState extends ConsumerState<ShopsManagePage> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();

    final requested = ref.read(shopsSegmentProvider);

    if (requested != null) {
      _tab = requested;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(shopsSegmentProvider.notifier).clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(shopsSegmentProvider, (_, next) {
      if (next == null) return;

      setState(() => _tab = next);
      ref.read(shopsSegmentProvider.notifier).clear();
      ref.invalidate(shopRequestsProvider);
    });

    final requestsCount =
        ref.watch(shopRequestsProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Магазины',
        showBack: false,
        actions: [
          AppIconButton(
            icon: Icons.groups_2_outlined,
            tooltip: 'Сотрудники',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const UsersManagePage())),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
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
                segments: [
                  const ButtonSegment(value: 0, label: Text('Магазины')),
                  const ButtonSegment(value: 1, label: Text('Долги')),
                  ButtonSegment(
                    value: 2,
                    label: Text(
                      requestsCount > 0 ? 'Заявки ($requestsCount)' : 'Заявки',
                    ),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (value) =>
                    setState(() => _tab = value.first),
              ),
            ),
          ),
          Expanded(
            child: switch (_tab) {
              0 => const ShopsListView(),
              1 => const DebtsView(),
              _ => const RequestsView(),
            },
          ),
        ],
      ),
    );
  }
}
