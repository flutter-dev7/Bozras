import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/device_location.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/launcher.dart';
import '../../../../core/utils/navigation_launcher.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../notifications/presentation/widgets/notifications_bell.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';
import '../providers/courier_providers.dart';
import '../widgets/courier_action_button.dart';
import '../widgets/status_badge.dart';

class CourierMapPage extends ConsumerStatefulWidget {
  const CourierMapPage({super.key});

  @override
  ConsumerState<CourierMapPage> createState() => _CourierMapPageState();
}

class _CourierMapPageState extends ConsumerState<CourierMapPage> {
  static const _dushanbe = LatLng(38.5598, 68.7870);

  final _controller = MapController();
  LatLng? _me;
  bool _locating = false;

  LatLng _pointOf(Order order) => LatLng(order.shopLatitude!, order.shopLongitude!);

  Future<LatLng?> _locate({bool move = true}) async {
    setState(() => _locating = true);

    final point = await currentLocation(context);

    if (!mounted) return null;

    setState(() {
      _locating = false;
      if (point != null) _me = point;
    });

    if (point != null && move) _controller.move(point, 16);

    return point;
  }

  Future<void> _nearest(List<Order> located) async {
    final pending = located.where((o) => o.status != OrderStatus.delivered).toList();

    if (pending.isEmpty) {
      AppSnackBar.show(context, 'Все заказы на карте доставлены');
      return;
    }

    final me = _me ?? await _locate(move: false);

    if (!mounted) return;

    if (me != null) {
      const distance = Distance();

      pending.sort(
        (a, b) => distance
            .as(LengthUnit.Meter, me, _pointOf(a))
            .compareTo(distance.as(LengthUnit.Meter, me, _pointOf(b))),
      );
    }

    final target = pending.first;

    _controller.move(_pointOf(target), 16);
    _showOrder(target);
  }

  void _showOrder(Order order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => _OrderSheet(
        initial: order,
        onDetails: () {
          Navigator.of(sheetContext).pop();
          context.push(AppRoutes.orderDetailsFor(order.id));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(courierTodayProvider);

    return Scaffold(
      appBar: const AppTopBar(
        title: 'Карта доставки',
        showBack: false,
        actions: [NotificationsBell()],
      ),
      body: orders.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: errorText(error),
          onRetry: () => ref.invalidate(courierTodayProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: AppIcons.truck,
              title: 'На сегодня заказов нет',
              message: 'Когда появятся заказы, магазины будут на карте.',
            );
          }

          final located = list.where((o) => o.hasShopLocation).toList();
          final missing = list.length - located.length;
          final left = list.where((o) => o.status != OrderStatus.delivered).length;
          final points = [for (final o in located) _pointOf(o)];

          return Stack(
            children: [
              FlutterMap(
                mapController: _controller,
                options: MapOptions(
                  initialCenter: _dushanbe,
                  initialZoom: 12,
                  initialCameraFit: points.isEmpty
                      ? null
                      : CameraFit.coordinates(
                          coordinates: points,
                          padding: const EdgeInsets.fromLTRB(48, 120, 48, 140),
                          maxZoom: 16,
                        ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'tj.non.non_app',
                  ),
                  MarkerLayer(
                    markers: [
                      for (final order in located)
                        Marker(
                          point: _pointOf(order),
                          width: 48,
                          height: 48,
                          alignment: Alignment.topCenter,
                          child: GestureDetector(
                            onTap: () => _showOrder(order),
                            child: Icon(
                              Icons.location_on,
                              size: 48,
                              color: StatusBadge.colorOf(order.status),
                            ),
                          ),
                        ),
                      if (_me != null)
                        Marker(
                          point: _me!,
                          width: 22,
                          height: 22,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2F6FDE),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const RichAttributionWidget(
                    attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
                  ),
                ],
              ),
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Material(
                  color: Colors.white,
                  elevation: 2,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Осталось доставить: $left из ${list.length}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (missing > 0)
                          Text(
                            'Без точки на карте: $missing (они только в списке «Сегодня»)',
                            style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FloatingActionButton.small(
                      heroTag: null,
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.brown,
                      onPressed: _locating ? null : _locate,
                      child: _locating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton.extended(
                      heroTag: null,
                      onPressed: located.isEmpty ? null : () => _nearest(located),
                      icon: const Icon(Icons.near_me),
                      label: const Text('Ближайший'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderSheet extends ConsumerWidget {
  const _OrderSheet({required this.initial, required this.onDetails});

  final Order initial;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref
            .watch(courierTodayProvider)
            .valueOrNull
            ?.where((o) => o.id == initial.id)
            .firstOrNull ??
        initial;

    final pieces = order.items.fold(0, (sum, item) => sum + item.quantity);
    final hasAction = nextCourierStatus(order) != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.shopName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                ),
              ),
              StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(AppIcons.location, size: 18, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.shopAddress,
                  style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$pieces шт. · ${order.paymentType.label} · ${Formatters.money(order.totalAmount)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (order.note != null && order.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(order.note!, style: const TextStyle(color: AppColors.muted)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              AppIconButton(
                icon: AppIcons.phone,
                tooltip: 'Позвонить',
                onPressed: () => callPhone(context, order.shopPhone),
              ),
              const SizedBox(width: 12),
              AppIconButton(
                icon: Icons.directions_rounded,
                tooltip: 'Маршрут',
                onPressed: () => openRoute(
                  context,
                  latitude: order.shopLatitude,
                  longitude: order.shopLongitude,
                  address: order.shopAddress,
                ),
              ),
              if (hasAction) ...[
                const SizedBox(width: 12),
                Expanded(child: CourierActionButton(order: order)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: onDetails, child: const Text('Подробнее о заказе')),
          ),
        ],
      ),
    );
  }
}