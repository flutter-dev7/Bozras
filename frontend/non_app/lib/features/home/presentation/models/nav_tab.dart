import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:non_app/features/orders/presentation/pages/admin_orders_page.dart';
import 'package:non_app/features/orders/presentation/pages/agent_orders_page.dart';
import 'package:non_app/features/orders/presentation/pages/catalog_page.dart';
import 'package:non_app/features/orders/presentation/pages/courier_history_page.dart';
import 'package:non_app/features/orders/presentation/pages/courier_map_page.dart';
import 'package:non_app/features/orders/presentation/pages/courier_today_page.dart';
import 'package:non_app/features/orders/presentation/pages/orders_page.dart';
import 'package:non_app/features/product_management/presentation/pages/products_manage_page.dart';
import 'package:non_app/features/reports/presentation/pages/plan_page.dart';
import 'package:non_app/features/shop_management/presentation/pages/shops_manage_page.dart';
import 'package:non_app/features/shops/presentation/pages/agent_shops_page.dart';
import 'package:non_app/features/visits/presentation/pages/visits_page.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class NavTab {
  const NavTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}

class _Soon extends StatelessWidget {
  const _Soon({required this.title, required this.icon, required this.message});

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyState(icon: icon, title: 'Скоро', message: message),
    );
  }
}

const _profileTab = NavTab(
  label: 'Профиль',
  icon: PhosphorIconsRegular.userCircle,
  selectedIcon: PhosphorIconsFill.userCircle,
  page: ProfilePage(),
);

List<NavTab> tabsFor(UserRole role) {
  switch (role) {
    case UserRole.shop:
      return const [
        NavTab(
          label: 'Заказать',
          icon: PhosphorIconsRegular.shoppingCart,
          selectedIcon: PhosphorIconsFill.shoppingCart,
          page: CatalogPage(),
        ),
        NavTab(
          label: 'Заказы',
          icon: PhosphorIconsRegular.clipboardText,
          selectedIcon: PhosphorIconsFill.clipboardText,
          page: OrdersPage(),
        ),
        _profileTab,
      ];

    case UserRole.courier:
      return const [
        NavTab(
          label: 'Сегодня',
          icon: PhosphorIconsRegular.truck,
          selectedIcon: PhosphorIconsFill.truck,
          page: CourierTodayPage(),
        ),
        NavTab(
          label: 'Карта',
          icon: PhosphorIconsRegular.mapTrifold,
          selectedIcon: PhosphorIconsFill.mapTrifold,
          page: CourierMapPage(),
        ),
        NavTab(
          label: 'История',
          icon: PhosphorIconsRegular.clockCounterClockwise,
          selectedIcon: PhosphorIconsFill.clockCounterClockwise,
          page: CourierHistoryPage(),
        ),
        _profileTab,
      ];

    case UserRole.agent:
      return const [
        NavTab(
          label: 'Магазины',
          icon: PhosphorIconsRegular.storefront,
          selectedIcon: PhosphorIconsFill.storefront,
          page: AgentShopsPage(),
        ),
        NavTab(
          label: 'Заказы',
          icon: PhosphorIconsRegular.clipboardText,
          selectedIcon: PhosphorIconsFill.clipboardText,
          page: AgentOrdersPage(),
        ),
        NavTab(
          label: 'Визиты',
          icon: PhosphorIconsRegular.mapPin,
          selectedIcon: PhosphorIconsFill.mapPin,
          page: VisitsPage(),
        ),
        _profileTab,
      ];

    case UserRole.admin:
      return const [
        NavTab(
          label: 'Заказы',
          icon: PhosphorIconsRegular.clipboardText,
          selectedIcon: PhosphorIconsFill.clipboardText,
          page: AdminOrdersPage(),
        ),
        NavTab(
          label: 'Товары',
          icon: PhosphorIconsRegular.package,
          selectedIcon: PhosphorIconsFill.package,
          page: ProductsManagePage(),
        ),
        NavTab(
          label: 'План',
          icon: PhosphorIconsRegular.chartBar,
          selectedIcon: PhosphorIconsFill.chartBar,
          page: PlanPage(),
        ),
        NavTab(
          label: 'Магазины',
          icon: PhosphorIconsRegular.storefront,
          selectedIcon: PhosphorIconsFill.storefront,
          page: ShopsManagePage(),
        ),
        _profileTab,
      ];
  }
}
