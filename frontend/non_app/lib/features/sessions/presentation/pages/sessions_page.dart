import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:non_app/core/widgets/app_dialogs.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decor.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/device_session.dart';
import '../providers/sessions_providers.dart';

class SessionsPage extends ConsumerWidget {
  const SessionsPage({super.key});

  Future<void> _revoke(BuildContext context, WidgetRef ref, DeviceSession session) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Завершить сеанс?',
      message: '${session.deviceName} будет выведено из аккаунта.',
      confirmLabel: 'Завершить',
      destructive: true,
    );

    if (!confirmed) return;

    try {
      await ref.read(revokeSessionUseCaseProvider)(session.id);

      ref.invalidate(sessionsProvider);

      if (context.mounted) AppSnackBar.show(context, 'Сеанс завершён');
    } on ApiException catch (e) {
      if (context.mounted) AppSnackBar.show(context, e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'Мои устройства'),
      body: sessions.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: errorText(error),
          onRetry: () => ref.invalidate(sessionsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: AppIcons.devices,
              title: 'Нет активных устройств',
              message: 'Здесь будут устройства, на которых вы вошли.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(sessionsProvider);
              await ref.read(sessionsProvider.future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final session = list[index];

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppDecor.fieldFill,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.smartphone_rounded, color: AppDecor.heroMid),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.deviceName,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Активность: ${Formatters.dateTime(session.lastActiveAt)}',
                                style: const TextStyle(color: AppColors.muted, fontSize: 13),
                              ),
                              if (session.isCurrent) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E9B5A).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'Это устройство',
                                    style: TextStyle(
                                      color: Color(0xFF2E9B5A),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!session.isCurrent)
                          AppIconButton(
                            icon: AppIcons.logout,
                            tooltip: 'Завершить сеанс',
                            onPressed: () => _revoke(context, ref, session),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}