import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/error_text.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../pages/connect_supplier_page.dart';
import '../pages/connection_pending_page.dart';
import '../pages/select_supplier_page.dart';
import '../pages/shop_profile_page.dart';
import '../providers/connections_providers.dart';

class ShopGate extends ConsumerWidget {
  const ShopGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(shopGateProvider);

    return gate.when(
      skipLoadingOnReload: true,
      loading: () => const Scaffold(body: LoadingView()),
      error: (error, _) => Scaffold(
        body: ErrorView(
          message: errorText(error),
          onRetry: () => ref.invalidate(shopGateProvider),
        ),
      ),
      data: (state) => switch (state.stage) {
        ShopStage.needsProfile => const ShopProfilePage(),
        ShopStage.needsConnection => const ConnectSupplierPage(),
        ShopStage.pending => const ConnectionPendingPage(),
        ShopStage.needsSelection => const SelectSupplierPage(),
        ShopStage.ready => child,
      },
    );
  }
}