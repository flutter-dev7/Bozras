import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:non_app/core/widgets/lazy_indexed_stack.dart';
import 'package:non_app/features/auth/domain/entities/user_role.dart';
import 'package:non_app/features/home/presentation/models/nav_tab.dart';
import 'package:non_app/features/shop_management/presentation/pages/shops_manage_page.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../connections/presentation/widgets/shop_gate.dart';
import '../providers/home_navigation_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _index = 0;

  void _consumeTarget(List<NavTab> tabs) {
    if (!mounted) return;

    final target = ref.read(homeTargetProvider);

    if (target == null) return;

    ref.read(homeTargetProvider.notifier).clear();

    switch (target) {
      case HomeTarget.shopRequests:
        final index = tabs.indexWhere((t) => t.page is ShopsManagePage);

        if (index < 0) return;

        ref.read(shopsSegmentProvider.notifier).request(2);
        setState(() => _index = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;

    if (user == null) return const SizedBox.shrink();

    final tabs = tabsFor(user.role);
    final index = _index.clamp(0, tabs.length - 1);

    if (ref.watch(homeTargetProvider) != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _consumeTarget(tabs));
    }

    final content = PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
        body: LazyIndexedStack(
          index: index,
          children: [for (final tab in tabs) tab.page],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: NavigationBar(
            height: 68,
            elevation: 0,
            selectedIndex: index,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: [
              for (final tab in tabs)
                NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.selectedIcon),
                  label: tab.label,
                ),
            ],
          ),
        ),
      ),
    );

    return user.role == UserRole.shop ? ShopGate(child: content) : content;
  }
}