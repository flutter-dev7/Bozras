import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_decor.dart';
import '../../../../core/utils/submit_state_mixin.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/inline_message.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/managed_shop.dart';
import '../providers/shop_management_providers.dart';
import '../utils/phone.dart';

class ShopEditPage extends ConsumerStatefulWidget {
  const ShopEditPage({super.key, required this.shop});

  final ManagedShop shop;

  @override
  ConsumerState<ShopEditPage> createState() => _ShopEditPageState();
}

class _ShopEditPageState extends ConsumerState<ShopEditPage>
    with SubmitStateMixin<ShopEditPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _contact;
  late bool _isActive;

  @override
  void initState() {
    super.initState();

    final s = widget.shop;

    _name = TextEditingController(text: s.name);
    _address = TextEditingController(text: s.address);
    _phone = TextEditingController(text: s.phone);
    _contact = TextEditingController(text: s.contactName ?? '');
    _isActive = s.isActive;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _contact.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'Заполните поле' : null;

  Future<void> _save() {
    return submit(_formKey, () async {
      final contact = _contact.text.trim();

      await ref.read(updateManagedShopUseCaseProvider)(
        widget.shop.id,
        name: _name.text.trim(),
        address: _address.text.trim(),
        phone: toApiPhone(_phone.text),
        contactName: contact.isEmpty ? null : contact,
        isActive: _isActive,
      );

      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Данные магазина'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            TextFormField(
              controller: _name,
              enabled: !loading,
              decoration: const InputDecoration(labelText: 'Название'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              enabled: !loading,
              decoration: const InputDecoration(labelText: 'Адрес'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              enabled: !loading,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Телефон'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contact,
              enabled: !loading,
              decoration: const InputDecoration(labelText: 'Контактное лицо'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppDecor.heroMid,
              title: const Text(
                'Активен',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              value: _isActive,
              onChanged: loading ? null : (v) => setState(() => _isActive = v),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              InlineMessage(message: error!),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Сохранить изменения',
              onPressed: _save,
              isLoading: loading,
            ),
          ],
        ),
      ),
    );
  }
}