import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_decor.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/submit_state_mixin.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/inline_message.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../shop_management/presentation/utils/phone.dart';
import '../../domain/entities/staff_user.dart';
import '../providers/user_management_providers.dart';

class UserFormPage extends ConsumerStatefulWidget {
  const UserFormPage({super.key, this.user});

  final StaffUser? user;

  @override
  ConsumerState<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends ConsumerState<UserFormPage>
    with SubmitStateMixin<UserFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late String _role;
  late bool _isActive;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();

    final u = widget.user;

    _firstName = TextEditingController(text: u?.firstName ?? '');
    _lastName = TextEditingController(text: u?.lastName ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _role = u != null && assignableRoles.contains(u.role) ? u.role : 'Agent';
    _isActive = u?.isActive ?? true;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Обязательное поле' : null;

  String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'Обязательное поле';
    if (!text.contains('@') || !text.contains('.')) return 'Неверный email';

    return null;
  }

  Future<void> _save() {
    return submit(_formKey, () async {
      final email = _email.text.trim();

      if (_isEdit) {
        await ref.read(updateStaffUserUseCaseProvider)(
          widget.user!.id,
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          email: email.isEmpty ? null : email,
          role: _role,
          isActive: _isActive,
        );
      } else {
        await ref.read(createStaffUserUseCaseProvider)(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          phone: toApiPhone(_phone.text),
          email: email,
          role: _role,
        );
      }

      ref.invalidate(staffUsersProvider);

      if (!mounted) return;

      AppSnackBar.show(
        context,
        _isEdit ? 'Сотрудник сохранён' : 'Сотрудник добавлен',
      );
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: _isEdit ? 'Сотрудник' : 'Новый сотрудник'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            TextFormField(
              controller: _firstName,
              enabled: !loading,
              validator: _required,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Имя'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastName,
              enabled: !loading,
              validator: _required,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Фамилия'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              enabled: !loading && !_isEdit,
              validator: _required,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Телефон',
                helperText: _isEdit ? 'Телефон изменить нельзя' : null,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              enabled: !loading,
              validator: _emailValidator,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Роль'),
              items: [
                for (final role in assignableRoles)
                  DropdownMenuItem(
                    value: role,
                    child: Text(staffRoleLabels[role]!),
                  ),
              ],
              onChanged: loading
                  ? null
                  : (value) => setState(() => _role = value ?? _role),
            ),
            if (_isEdit)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppDecor.heroMid,
                title: const Text(
                  'Активен',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Заблокированный не сможет войти.'),
                value: _isActive,
                onChanged: loading
                    ? null
                    : (value) => setState(() => _isActive = value),
              ),
            if (error != null) ...[
              const SizedBox(height: 12),
              InlineMessage(message: error!),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              label: _isEdit ? 'Сохранить' : 'Добавить',
              onPressed: _save,
              isLoading: loading,
            ),
          ],
        ),
      ),
    );
  }
}