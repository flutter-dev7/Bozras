import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:non_app/features/notifications/presentation/provider/inbox_provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decor.dart';
import '../../../../core/widgets/app_top_bar.dart';

class NotificationsBell extends ConsumerWidget {
  const NotificationsBell({super.key});

  void _open(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => const _InboxSheet(),
    ).whenComplete(() => ref.read(inboxProvider.notifier).markAllRead());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);

    return Badge(
      isLabelVisible: unread > 0,
      label: Text(unread > 9 ? '9+' : '$unread'),
      offset: const Offset(-2, 2),
      child: AppIconButton(
        icon: Icons.notifications_none_rounded,
        tooltip: 'Уведомления',
        onPressed: () => _open(context, ref),
      ),
    );
  }
}

class _InboxSheet extends ConsumerWidget {
  const _InboxSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inboxProvider);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Уведомления',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                if (items.isNotEmpty)
                  TextButton(
                    onPressed: () => ref.read(inboxProvider.notifier).clear(),
                    child: const Text('Очистить'),
                  ),
              ],
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 48),
              child: Center(
                child: Text(
                  'Пока нет уведомлений.\nЗдесь появятся изменения по заказам.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];

                  return Material(
                    color: item.read ? AppDecor.fieldFill : AppDecor.heroMid.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: item.orderId == null
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              context.push(AppRoutes.orderDetailsFor(item.orderId!));
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.notifications_active_outlined, color: AppDecor.heroMid),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.title.isNotEmpty)
                                    Text(
                                      item.title,
                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                  if (item.body.isNotEmpty)
                                    Text(
                                      item.body,
                                      style: const TextStyle(color: AppColors.brown),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd.MM HH:mm').format(item.receivedAt),
                                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}