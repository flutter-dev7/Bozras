import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:non_app/core/network/api_exception.dart';
import 'package:non_app/core/utils/app_snackbar.dart';
import 'package:non_app/core/utils/image_url.dart';

import '../../../../core/theme/app_decor.dart';
import '../../../../core/utils/submit_state_mixin.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/inline_message.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/managed_product.dart';
import '../../domain/entities/product_input.dart';
import '../providers/product_management_providers.dart';

const _units = ['шт', 'кг', 'уп.', 'л', 'бут.'];

class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({super.key, this.product});

  final ManagedProduct? product;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage>
    with SubmitStateMixin<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _weight;
  late String _unit;
  late bool _isActive;
  String? _categoryId;
  String? _imageUrl;
  String? _localPath;
  bool _uploading = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();

    final p = widget.product;

    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(
      text: p == null ? '' : p.price.toStringAsFixed(p.price % 1 == 0 ? 0 : 2),
    );
    _weight = TextEditingController(text: p?.weightInGrams?.toString() ?? '');
    _unit = p?.unit ?? 'шт';
    _isActive = p?.isActive ?? true;
    _categoryId = p?.categoryId;
    _imageUrl = p?.imageUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );

    if (picked == null || !mounted) return;

    if (await picked.length() > 5 * 1024 * 1024) {
      if (mounted) AppSnackBar.show(context, 'Не более 5 МБ', isError: true);
      return;
    }

    setState(() {
      _localPath = picked.path;
      _uploading = true;
    });

    try {
      final url = await ref.read(uploadProductImageUseCaseProvider)(
        picked.path,
      );

      if (mounted) setState(() => _imageUrl = url);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _localPath = null);
        AppSnackBar.show(context, e.message, isError: true);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removeImage() {
    setState(() {
      _imageUrl = null;
      _localPath = null;
    });
  }

  Future<void> _save() {
    return submit(_formKey, () async {
      final weightText = _weight.text.trim();

      final input = ProductInput(
        name: _name.text.trim(),
        price: double.parse(_price.text.trim().replaceAll(',', '.')),
        unit: _unit,
        weightInGrams: weightText.isEmpty ? null : int.parse(weightText),
        imageUrl: _imageUrl,
        categoryId: _categoryId,
      );

      if (_isEdit) {
        await ref.read(updateProductUseCaseProvider)(
          widget.product!.id,
          input,
          _isActive,
        );
      } else {
        await ref.read(createProductUseCaseProvider)(input);
      }

      ref.invalidate(manageCategoriesProvider);

      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(manageCategoriesProvider).valueOrNull ?? const [];
    final unitOptions = _units.contains(_unit) ? _units : [..._units, _unit];
    final categoryValue = categories.any((c) => c.id == _categoryId)
        ? _categoryId
        : null;

    return Scaffold(
      appBar: AppTopBar(
        title: _isEdit ? 'Редактирование товара' : 'Новый товар',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _PhotoPicker(
              localPath: _localPath,
              imageUrl: _imageUrl,
              uploading: _uploading,
              enabled: !loading,
              onPick: _pickImage,
              onRemove: _removeImage,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              enabled: !loading,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Название'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Введите название' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: categoryValue,
              decoration: const InputDecoration(labelText: 'Категория'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Без категории'),
                ),
                for (final c in categories)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: loading
                  ? null
                  : (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    enabled: !loading,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(labelText: 'Цена, сом.'),
                    validator: (v) {
                      final value = double.tryParse(
                        (v ?? '').trim().replaceAll(',', '.'),
                      );

                      return value == null || value < 0 ? 'Введите цену' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: const InputDecoration(labelText: 'Единица'),
                    items: [
                      for (final u in unitOptions)
                        DropdownMenuItem(value: u, child: Text(u)),
                    ],
                    onChanged: loading
                        ? null
                        : (v) => setState(() => _unit = v ?? _unit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weight,
              enabled: !loading,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Вес, г',
                hintText: 'Необязательно',
              ),
              validator: (v) {
                final text = (v ?? '').trim();

                if (text.isEmpty) return null;

                final value = int.tryParse(text);

                return value == null || value < 1 || value > 100000
                    ? 'От 1 до 100000 г'
                    : null;
              },
            ),
            if (_isEdit) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppDecor.heroMid,
                title: const Text(
                  'В продаже',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  _isActive ? 'Виден магазинам' : 'Скрыт от магазинов',
                ),
                value: _isActive,
                onChanged: loading
                    ? null
                    : (v) => setState(() => _isActive = v),
              ),
              Text(
                'Остаток на складе: ${widget.product!.stockQuantity} ${widget.product!.unit}. '
                'Меняется через «Приход и списание» в списке.',
                style: const TextStyle(fontSize: 13),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 16),
              InlineMessage(message: error!),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: _isEdit ? 'Сохранить' : 'Добавить товар',
              onPressed: _uploading ? null : _save,
              isLoading: loading,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.localPath,
    required this.imageUrl,
    required this.uploading,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  final String? localPath;
  final String? imageUrl;
  final bool uploading;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final resolved = imageUrl == null ? null : resolveImageUrl(imageUrl!);
    final hasImage = localPath != null || resolved != null;

    Widget content;

    if (localPath != null) {
      content = Image.file(File(localPath!), fit: BoxFit.cover);
    } else if (resolved != null) {
      content = Image.network(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
      );
    } else {
      content = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, color: AppDecor.heroMid, size: 30),
          SizedBox(height: 6),
          Text('Добавить фото', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      );
    }

    return Center(
      child: Column(
        children: [
          InkWell(
            onTap: enabled && !uploading ? onPick : null,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 140,
              height: 140,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppDecor.fieldFill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(child: content),
                  if (localPath != null || resolved != null)
                    SizedBox.expand(child: content),
                  if (uploading)
                    Container(
                      color: Colors.white.withValues(alpha: 0.7),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (hasImage && !uploading)
            TextButton(
              onPressed: enabled ? onRemove : null,
              child: const Text('Удалить фото'),
            ),
        ],
      ),
    );
  }
}