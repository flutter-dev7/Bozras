import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/services/push_service.dart';
import '../../domain/entities/app_notification.dart';

final inboxProvider = NotifierProvider<InboxNotifier, List<AppNotification>>(
  InboxNotifier.new,
);

final unreadCountProvider = Provider<int>(
  (ref) => ref.watch(inboxProvider).where((n) => !n.read).length,
);

class InboxNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() {
    ref.watch(currentUserIdProvider);

    return const [];
  }

  void add(RemoteMessage message, {bool read = false}) {
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';

    if (title.isEmpty && body.isEmpty) return;

    final id = message.messageId ?? DateTime.now().microsecondsSinceEpoch.toString();

    if (state.any((n) => n.id == id)) return;

    final item = AppNotification(
      id: id,
      title: title,
      body: body,
      orderId: PushService.orderIdOf(message),
      receivedAt: DateTime.now(),
      read: read,
    );

    state = [item, ...state].take(50).toList();
  }

  void markAllRead() {
    if (state.every((n) => n.read)) return;

    state = [for (final n in state) n.read ? n : n.markRead()];
  }

  void clear() => state = const [];
}