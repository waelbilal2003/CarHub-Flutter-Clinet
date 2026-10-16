import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../providers/merchant_provider.dart';
import '../widgets/merchant_scaffold.dart';

/// إضافة قطعة جديدة — POST /merchant/products (multipart/form-data).
///
/// ⚠️ نقطة حرجة تحقّقنا منها بالتشغيل: الحقل `images` **مطلوب**
/// (`required|array|min:1`)، وكل صورة يجب أن تكون jpeg/png/jpg/gif/webp
/// وبحجم 2MB أو أقل. مثال Postman لا يرسل صوراً إطلاقاً فيفشل بـ 422 —
/// لذلك لا يمكن نشر قطعة بلا صورة، وزر النشر معطّل حتى تُختار واحدة.
class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  final _picker = ImagePicker();
  final List<XFile> _images = [];

  /// حد الخادم لكل صورة: 2048KB.
  static const int _maxImageBytes = 2048 * 1024;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(
      // نضغط عند الالتقاط حتى نبقى تحت حد 2MB الذي يفرضه الخادم.
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked.isEmpty || !mounted) return;

    final tooLarge = <String>[];
    for (final file in picked) {
      if (await file.length() > _maxImageBytes) {
        tooLarge.add(file.name);
      } else {
        _images.add(file);
      }
    }
    if (!mounted) return;
    setState(() {});

    if (tooLarge.isNotEmpty) {
      AppSnackBar.showError(
        context,
        'تجاوزت هذه الصور حدّ 2 ميغابايت ولم تُضف: ${tooLarge.join('، ')}',
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      AppSnackBar.showError(context, 'أضف صورة واحدة على الأقل للقطعة.');
      return;
    }

    final ok = await ref.read(addProductProvider.notifier).submit(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          stock: int.parse(_stockController.text.trim()),
          imagePaths: _images.map((f) => f.path).toList(),
        );
    if (!mounted) return;

    if (!ok) {
      final error = ref.read(addProductProvider).error;
      AppSnackBar.showError(context, error ?? 'تعذّر إضافة القطعة.');
      return;
    }

    // القطعة الجديدة يجب أن تظهر في المخزون وفي السوق فوراً.
    ref.read(merchantProductsProvider.notifier).refreshList();
    ref.read(productListProvider.notifier).refreshList();

    AppSnackBar.showSuccess(context, 'تمت إضافة القطعة بنجاح.');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addProductProvider);

    return MerchantScaffold(
      title: 'إضافة قطعة جديدة',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.containerPadding),
          children: [
            const Text('صور القطعة', style: AppTextStyles.headlineMd),
            const SizedBox(height: AppDimensions.spaceXS),
            const Text(
              'صورة واحدة على الأقل مطلوبة. الأولى هي الصورة الأساسية '
              'التي تظهر في السوق.',
              style: AppTextStyles.bodySm,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            _ImagePickerRow(
              images: _images,
              onAdd: _pickImages,
              onRemove: (index) => setState(() => _images.removeAt(index)),
            ),

            const SizedBox(height: AppDimensions.spaceXL),
            const Text('بيانات القطعة', style: AppTextStyles.headlineMd),
            const SizedBox(height: AppDimensions.spaceM),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'اسم القطعة',
                hintText: 'مثال: فحمات فرامل أمامية سيراميك',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'اسم القطعة مطلوب.'
                  : null,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'الوصف',
                hintText: 'المواصفات، الموديلات المتوافقة، حالة القطعة...',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'الوصف مطلوب.'
                  : null,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'السعر (ر.س)',
                      hintText: '450',
                    ),
                    validator: _validatePrice,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'الكمية',
                      hintText: '24',
                    ),
                    validator: _validateStock,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            PrimaryButton(
              label: 'نشر القطعة في السوق',
              isLoading: state.isLoading,
              onPressed: _images.isEmpty ? null : _submit,
            ),
            if (_images.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: AppDimensions.spaceS),
                child: Text(
                  'الزر معطّل حتى تضيف صورة — الخادم يرفض القطع بلا صور.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSm,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String? _validatePrice(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'السعر مطلوب.';
    final price = double.tryParse(text);
    if (price == null) return 'أدخل رقماً صحيحاً.';
    if (price < 0) return 'السعر لا يكون سالباً.';
    return null;
  }

  static String? _validateStock(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'الكمية مطلوبة.';
    final stock = int.tryParse(text);
    if (stock == null) return 'أدخل عدداً صحيحاً.';
    if (stock < 0) return 'الكمية لا تكون سالبة.';
    return null;
  }
}

/// شريط أفقي للصور المختارة مع مربّع «إضافة» في أوله.
/// الصورة الأولى موسومة بـ«أساسية» لأنها `primary_image_index = 0`.
class _ImagePickerRow extends StatelessWidget {
  final List<XFile> images;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _ImagePickerRow({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _AddTile(onTap: onAdd),
          for (var i = 0; i < images.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.spaceS),
              child: _Thumb(
                file: images[i],
                isPrimary: i == 0,
                onRemove: () => onRemove(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppDimensions.spaceS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
        child: Container(
          width: 100,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, color: AppColors.secondary),
              SizedBox(height: 6),
              Text('إضافة صورة', style: AppTextStyles.labelSm),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final XFile file;
  final bool isPrimary;
  final VoidCallback onRemove;

  const _Thumb({
    required this.file,
    required this.isPrimary,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
          child: Image.file(
            File(file.path),
            width: 100,
            height: 110,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          left: 4,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: AppColors.error),
            ),
          ),
        ),
        if (isPrimary)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              ),
              child: Text(
                'أساسية',
                style: AppTextStyles.labelSm.copyWith(color: AppColors.white),
              ),
            ),
          ),
      ],
    );
  }
}
