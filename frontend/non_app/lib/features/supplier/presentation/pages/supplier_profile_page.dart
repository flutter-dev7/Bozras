import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:non_app/core/widgets/app_dialogs.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decor.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/submit_state_mixin.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/inline_message.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../shop_management/presentation/utils/phone.dart';
import '../../domain/entities/supplier_profile.dart';
import '../providers/supplier_providers.dart';

String _statusLabel(String status) => switch (status) {
  'Trial' => 'Пробный период',
  'Active' => 'Активна',
  'PastDue' => 'Просрочена',
  'Suspended' => 'Приостановлена',
  _ => status,
};

class SupplierProfilePage extends ConsumerWidget {
  const SupplierProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(supplierProfileProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'Профиль поставщика'),
      body: profile.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: errorText(error),
          onRetry: () => ref.invalidate(supplierProfileProvider),
        ),
        data: (data) => _ProfileBody(profile: data),
      ),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.profile});

  final SupplierProfile profile;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody>
    with SubmitStateMixin<_ProfileBody> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _phone;
  late final TextEditingController _description;
  late bool _requiresApproval;
  bool _regenerating = false;

  @override
  void initState() {
    super.initState();

    final p = widget.profile;

    _phone = TextEditingController(text: p.phone ?? '');
    _description = TextEditingController(text: p.description ?? '');
    _requiresApproval = p.requiresApproval;
  }

  @override
  void dispose() {
    _phone.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.profile.code));

    if (mounted) AppSnackBar.show(context, 'Код скопирован');
  }

  Future<void> _regenerate() async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Создать новый код?',
      message:
          'Старый код перестанет работать. Уже подключённые магазины останутся.',
      confirmLabel: 'Создать новый',
      destructive: true,
    );

    if (!confirmed) return;

    setState(() => _regenerating = true);

    try {
      await ref.read(regenerateSupplierCodeUseCaseProvider)();

      ref.invalidate(supplierProfileProvider);

      if (mounted) AppSnackBar.show(context, 'Код обновлён');
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.show(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  Future<void> _save() {
    return submit(_formKey, () async {
      final phone = _phone.text.trim();
      final description = _description.text.trim();

      await ref.read(updateSupplierProfileUseCaseProvider)(
        phone: phone.isEmpty ? null : toApiPhone(phone),
        description: description.isEmpty ? null : description,
        requiresApproval: _requiresApproval,
      );

      ref.invalidate(supplierProfileProvider);

      if (mounted) AppSnackBar.show(context, 'Профиль сохранён');
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final ends = profile.subscriptionEndsAt;
    final daysLeft = ends?.difference(DateTime.now()).inDays;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppDecor.heroGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Код подключения',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 30,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy_rounded, color: Colors.white),
                      tooltip: 'Скопировать',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Передайте код магазину, чтобы он подключился к вам.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _regenerating ? null : _regenerate,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Создать новый код'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Подписка',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  _InfoRow('Тариф', profile.planName ?? '—'),
                  _InfoRow('Статус', _statusLabel(profile.subscriptionStatus)),
                  if (ends != null)
                    _InfoRow(
                      'Действует до',
                      '${Formatters.date(ends)}'
                      '${daysLeft != null && daysLeft >= 0 ? ' (осталось $daysLeft дн.)' : ''}',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Данные для магазинов',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            enabled: !loading,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Телефон'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _description,
            enabled: !loading,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'Описание'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppDecor.heroMid,
            title: const Text(
              'Подтверждать магазины вручную',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Новые магазины попадут в «Заявки» и подключатся после вашего решения.',
            ),
            value: _requiresApproval,
            onChanged: loading
                ? null
                : (v) => setState(() => _requiresApproval = v),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            InlineMessage(message: error!),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Сохранить',
            onPressed: _save,
            isLoading: loading,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}