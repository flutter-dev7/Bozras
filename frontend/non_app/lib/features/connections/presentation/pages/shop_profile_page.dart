import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:non_app/features/shops/presentation/widgets/location_field.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/utils/submit_state_mixin.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/inline_message.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/location_item.dart';
import '../../domain/entities/shop_profile.dart';
import '../providers/connections_providers.dart';
import '../widgets/region_field.dart';
import 'region_picker_page.dart';

class ShopProfilePage extends ConsumerStatefulWidget {
  const ShopProfilePage({super.key});

  @override
  ConsumerState<ShopProfilePage> createState() => _ShopProfilePageState();
}

class _ShopProfilePageState extends ConsumerState<ShopProfilePage>
    with SubmitStateMixin<ShopProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _contact = TextEditingController();

  String? _regionId;
  String? _regionName;
  bool _regionMissing = false;
  LatLng? _point;
  bool _filled = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _contact.dispose();
    super.dispose();
  }

  void _prefill(ShopProfile? profile) {
    if (_filled) return;

    _filled = true;

    if (profile == null) return;

    _name.text = profile.name;
    _address.text = profile.address;
    _phone.text = profile.phone.replaceFirst('+992', '').trim();
    _contact.text = profile.contactName ?? '';
    _regionId = profile.locationId;
    _regionName = profile.locationName;

    if (profile.latitude != null && profile.longitude != null) {
      _point = LatLng(profile.latitude!, profile.longitude!);
    }
  }

  Future<void> _pickRegion() async {
    final picked = await Navigator.of(context).push<LocationItem>(
      MaterialPageRoute(builder: (_) => const RegionPickerPage()),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _regionId = picked.id;
      _regionName = picked.name;
      _regionMissing = false;
    });
  }

  Future<void> _submit() async {
    if (_regionId == null) {
      setState(() => _regionMissing = true);
      return;
    }

    await submit(_formKey, () async {
      final contact = _contact.text.trim();

      await ref.read(saveShopProfileUseCaseProvider)(
        name: _name.text.trim(),
        address: _address.text.trim(),
        phone: Validators.toApiPhone(_phone.text),
        contactName: contact.isEmpty ? null : contact,
        locationId: _regionId!,
        latitude: _point?.latitude,
        longitude: _point?.longitude,
      );

      await ref.read(shopGateProvider.notifier).reload();

      if (!mounted) return;

      AppSnackBar.show(context, 'Профиль сохранён');

      if (context.canPop()) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(shopProfileProvider);

    return Scaffold(
      appBar: AppTopBar(title: 'Профиль магазина', showBack: context.canPop()),
      body: SafeArea(
        child: profile.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: errorText(error),
            onRetry: () => ref.invalidate(shopProfileProvider),
          ),
          data: (data) {
            _prefill(data);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _name,
                          label: 'Название магазина',
                          hint: 'Например, Сомон',
                          icon: AppIcons.store,
                          textInputAction: TextInputAction.next,
                          validator: Validators.name,
                          enabled: !loading,
                        ),
                        const SizedBox(height: 18),
                        AppTextField(
                          controller: _address,
                          label: 'Адрес',
                          hint: 'Улица, дом',
                          icon: AppIcons.location,
                          textInputAction: TextInputAction.next,
                          validator: Validators.required,
                          enabled: !loading,
                        ),
                        const SizedBox(height: 18),
                        AppTextField(
                          controller: _phone,
                          label: 'Телефон магазина',
                          hint: '900 00 00 00',
                          icon: AppIcons.phone,
                          prefixText: '+992 ',
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                          ],
                          validator: Validators.phone,
                          enabled: !loading,
                        ),
                        const SizedBox(height: 18),
                        AppTextField(
                          controller: _contact,
                          label: 'Контактное лицо (необязательно)',
                          hint: 'Кого спросить',
                          icon: AppIcons.user,
                          textInputAction: TextInputAction.done,
                          enabled: !loading,
                        ),
                        const SizedBox(height: 18),
                        RegionField(
                          regionName: _regionName,
                          showError: _regionMissing,
                          enabled: !loading,
                          onTap: _pickRegion,
                        ),
                        const SizedBox(height: 18),
                        LocationField(
                          value: _point,
                          enabled: !loading,
                          onChanged: (point) => setState(() => _point = point),
                        ),
                      ],
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    InlineMessage(message: error!),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Сохранить',
                    onPressed: _submit,
                    isLoading: loading,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}