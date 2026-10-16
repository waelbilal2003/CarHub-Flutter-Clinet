import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../../shared/widgets/network_image_box.dart';
import '../../../products/domain/entities/product.dart';
import '../providers/merchant_provider.dart';
import '../widgets/merchant_scaffold.dart';

/// شاشة المخزون — GET /merchant/products (منتجات التاجر بكل الحالات).
///
/// مطابقة لـ 03_inventory_management.html في: عنوان «المخزون» ونص فرعي،
/// شريط بحث وزر «إضافة قطعة جديدة» أخضر، ثم بطاقات فيها صورة، السعر
/// بالأخضر، الاسم، ومؤشّر توفّر بنقطة ملوّنة وزرّا تعديل وحذف.
///
/// ملاحظة: البحث هنا محلي داخل الصفحات المحمّلة — مسار مخزون التاجر
/// لا يقبل معامل `search` (بخلاف GET /products العام).
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(merchantProductsProvider);

    return MerchantScaffold(
      navIndex: 2,
      title: 'المخزون',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppRoutes.addProduct);
          // نعيد التحميل بعد العودة ليظهر المنتج الجديد فوراً.
          if (context.mounted) {
            ref.read(merchantProductsProvider.notifier).refreshList();
          }
        },
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('إضافة قطعة'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(merchantProductsProvider.notifier).refreshList(),
        child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _Message(
            message: e.toString(),
            actionLabel: 'إعادة المحاولة',
            onAction: () =>
                ref.read(merchantProductsProvider.notifier).refreshList(),
          ),
          data: (mine) {
            final visible = _query.trim().isEmpty
                ? mine
                : mine.where((p) => p.title.contains(_query.trim())).toList();

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.containerPadding,
                AppDimensions.spaceL,
                AppDimensions.containerPadding,
                140,
              ),
              children: [
                const Text('المخزون', style: AppTextStyles.headlineXl),
                const SizedBox(height: AppDimensions.spaceXS),
                const Text(
                  'إدارة قطع الغيار والأسعار والكميات المتاحة.',
                  style: AppTextStyles.bodySm,
                ),
                const SizedBox(height: AppDimensions.spaceM),
                _StockSummary(products: mine),
                const SizedBox(height: AppDimensions.spaceM),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'ابحث في قطعك...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusInput),
                      borderSide:
                          const BorderSide(color: AppColors.outlineVariant),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceL),
                if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppDimensions.spaceXL),
                    child: _Message(
                      message: mine.isEmpty
                          ? 'لا توجد قطع في مخزونك بعد. أضف قطعتك الأولى '
                              'من الزر بالأسفل.'
                          : 'لا نتائج مطابقة لبحثك.',
                      actionLabel: 'إضافة قطعة جديدة',
                      onAction: () => context.push(AppRoutes.addProduct),
                    ),
                  )
                else
                  for (final product in visible)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppDimensions.cardGap),
                      child: _InventoryCard(product: product),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// شريط ملخّص صغير — عدد القطع وكم منها منخفض أو نافد.
/// أرقام محسوبة من المخزون المحمّل فعلاً، لا من endpoint إحصائيات.
class _StockSummary extends StatelessWidget {
  final List<Product> products;
  const _StockSummary({required this.products});

  @override
  Widget build(BuildContext context) {
    final out = products.where((p) => p.isOutOfStock).length;
    final low = products.where((p) => p.isLowStock).length;

    return Row(
      children: [
        _Pill(label: '${products.length} قطعة', color: AppColors.secondary),
        if (low > 0) ...[
          const SizedBox(width: AppDimensions.spaceS),
          _Pill(label: '$low منخفضة', color: AppColors.warning),
        ],
        if (out > 0) ...[
          const SizedBox(width: AppDimensions.spaceS),
          _Pill(label: '$out نافدة', color: AppColors.error),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Text(label,
          style: AppTextStyles.labelSm.copyWith(color: color)),
    );
  }
}

/// بطاقة قطعة في المخزون.
class _InventoryCard extends ConsumerStatefulWidget {
  final Product product;
  const _InventoryCard({required this.product});

  @override
  ConsumerState<_InventoryCard> createState() => _InventoryCardState();
}

class _InventoryCardState extends ConsumerState<_InventoryCard> {
  bool _isBusy = false;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف القطعة'),
        content: Text(
          'سيُحذف «${widget.product.title}» وصوره نهائياً من السوق. '
          'لا يمكن التراجع.',
          style: AppTextStyles.bodySm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('تراجع'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    final error =
        await ref.read(merchantProductsProvider.notifier).remove(widget.product.id);
    if (!mounted) return;
    setState(() => _isBusy = false);

    if (error != null) {
      AppSnackBar.showError(context, error);
    } else {
      AppSnackBar.showSuccess(context, 'تم حذف القطعة.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final stockColor = product.isOutOfStock
        ? AppColors.error
        : product.isLowStock
            ? AppColors.warning
            : AppColors.primaryContainer;

    return Opacity(
      opacity: _isBusy ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          border: Border.all(color: AppColors.surfaceContainerHighest),
          boxShadow: AppDimensions.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetworkImageBox(
              url: product.primaryImageUrl,
              width: 88,
              height: 88,
              placeholderIconSize: 30,
            ),
            const SizedBox(width: AppDimensions.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: AppTextStyles.labelBold,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        Formatters.price(product.price),
                        style: AppTextStyles.labelBold
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: AppTextStyles.labelSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.spaceS),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: stockColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('متوفّر: ${product.stock}',
                          style: AppTextStyles.labelSm),
                      const Spacer(),
                      IconButton(
                        tooltip: 'تعديل',
                        visualDensity: VisualDensity.compact,
                        onPressed: _isBusy
                            ? null
                            : () => _EditSheet.open(context, product),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                      IconButton(
                        tooltip: 'حذف',
                        visualDensity: VisualDensity.compact,
                        onPressed: _isBusy ? null : _confirmDelete,
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: AppColors.error),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ورقة تعديل سريعة — PUT /merchant/products/{id}.
/// تكتفي بالحقول النصية؛ استبدال الصور يحتاج شاشة أوسع.
class _EditSheet extends ConsumerStatefulWidget {
  final Product product;
  const _EditSheet({required this.product});

  static void open(BuildContext context, Product product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)),
      ),
      builder: (_) => _EditSheet(product: product),
    );
  }

  @override
  ConsumerState<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends ConsumerState<_EditSheet> {
  late final _titleController =
      TextEditingController(text: widget.product.title);
  late final _descriptionController =
      TextEditingController(text: widget.product.description);
  late final _priceController = TextEditingController(
      text: widget.product.price == widget.product.price.roundToDouble()
          ? widget.product.price.toInt().toString()
          : widget.product.price.toString());
  late final _stockController =
      TextEditingController(text: widget.product.stock.toString());
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final price = double.tryParse(_priceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim());
    if (price == null || stock == null) {
      AppSnackBar.showError(context, 'السعر والكمية يجب أن يكونا أرقاماً.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = await ref.read(merchantRepositoryProvider).updateProduct(
            id: widget.product.id,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            price: price,
            stock: stock,
          );
      if (!mounted) return;
      ref.read(merchantProductsProvider.notifier).replace(updated);
      Navigator.of(context).pop();
      AppSnackBar.showSuccess(context, 'تم تحديث القطعة.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackBar.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.containerPadding,
        AppDimensions.spaceL,
        AppDimensions.containerPadding,
        MediaQuery.of(context).viewInsets.bottom + AppDimensions.spaceL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تعديل القطعة', style: AppTextStyles.headlineMd),
          const SizedBox(height: AppDimensions.spaceM),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'الاسم'),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'الوصف'),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'السعر (ر.س)'),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: TextField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الكمية'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceL),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : const Text('حفظ التعديلات'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _Message({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.inventory_2_outlined,
            size: 56, color: AppColors.textHint),
        const SizedBox(height: AppDimensions.spaceM),
        Text(message, textAlign: TextAlign.center, style: AppTextStyles.bodySm),
        const SizedBox(height: AppDimensions.spaceM),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}
