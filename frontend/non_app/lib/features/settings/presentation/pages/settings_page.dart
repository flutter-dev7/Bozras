import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decor.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/utils/submit_state_mixin.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/inline_message.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cutoff = ref.watch(orderCutoffProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'Время приёма заказов'),
      body: cutoff.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: errorText(error),
          onRetry: () => ref.invalidate(orderCutoffProvider),
        ),
        data: (saved) => _CutoffBody(saved: saved),
      ),
    );
  }
}

class _CutoffBody extends ConsumerStatefulWidget {
  const _CutoffBody({required this.saved});

  final String saved;

  @override
  ConsumerState<_CutoffBody> createState() => _CutoffBodyState();
}

class _CutoffBodyState extends ConsumerState<_CutoffBody>
    with SubmitStateMixin<_CutoffBody> {
  final _formKey = GlobalKey<FormState>();

  late TimeOfDay _time;

  static TimeOfDay _parse(String value) {
    final parts = value.split(':');

    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 0,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  static String _format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();

    _time = _parse(widget.saved);
  }

  bool get _changed => _format(_time) != _format(_parse(widget.saved));

  Future<void> _pick() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );

    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() {
    return submit(_formKey, () async {
      await ref.read(updateOrderCutoffUseCaseProvider)(_format(_time));

      ref.invalidate(orderCutoffProvider);

      if (mounted) AppSnackBar.show(context, 'Время приёма заказов сохранено');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Text(
            'Магазины и агенты могут оформить заказ на завтра только до этого '
            'времени (время Таджикистана). После него заказы принимаются на '
            'послезавтра и позже. Для администратора ограничение не действует.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: loading ? null : _pick,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: AppDecor.fieldFill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    _format(_time),
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Нажмите, чтобы изменить',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            InlineMessage(message: error!),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Сохранить',
            onPressed: _changed ? _save : null,
            isLoading: loading,
          ),
        ],
      ),
    );
  }
}