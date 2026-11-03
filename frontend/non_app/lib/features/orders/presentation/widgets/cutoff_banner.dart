import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decor.dart';
import '../../../../core/utils/formatters.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class CutoffBanner extends ConsumerStatefulWidget {
  const CutoffBanner({super.key});

  @override
  ConsumerState<CutoffBanner> createState() => _CutoffBannerState();
}

class _CutoffBannerState extends ConsumerState<CutoffBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration? _left(String? cutoff) {
    final parts = cutoff?.split(':');

    if (parts == null || parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    final now = Formatters.nowTj();
    final end = DateTime(now.year, now.month, now.day, hour, minute);

    return end.difference(now);
  }

  String _format(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;

    if (hours == 0) return '$minutes мин';

    return '$hours ч $minutes мин';
  }

  @override
  Widget build(BuildContext context) {
    final cutoff = ref.watch(orderCutoffProvider).valueOrNull;
    final left = _left(cutoff);

    if (cutoff == null || left == null) return const SizedBox.shrink();

    final open = !left.isNegative && left.inMinutes > 0;
    final color = open ? AppDecor.heroMid : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              open
                  ? 'Заказы на завтра принимаются до $cutoff. Осталось ${_format(left)}.'
                  : 'Приём заказов на завтра закрыт. Ближайшая дата доставки: послезавтра.',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brown),
            ),
          ),
        ],
      ),
    );
  }
}