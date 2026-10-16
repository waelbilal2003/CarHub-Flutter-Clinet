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
import '../../domain/entities/cart.dart';
import '../providers/cart_provider.dart';

/// شاشة السلة — GET /cart مع تعديل وحذف حقيقيين:
///   PUT    /cart/items/{id}  { quantity }
///   DELETE /cart/items/{id}
///   DELETE /cart
///
/// مطابقة لـ 10_cart.html في: رأس بتدرّج كحلي وعنوان أخضر، بطاقة بيضاء
/// بزوايا 12 وظل ناعم، صورة 80×80 لكل عنصر، محدّد كمية بشكل حبّة رمادية
/// بحدّ رفيع، وشريط سفلي ثابت يعرض «الإجمالي الكلي» بالأخضر وزر
/// «إتمام الطلب» بشكل حبّة.
///
/// ⚠️ اختلاف واحد باقٍ عن التصميم: التصميم يجمّع العناصر **حسب المتجر**
/// مع مجموع فرعي لكل متجر. الخادم لا يُحمّل علاقة التاجر داخل عنصر
/// السلة (`CartController` يُحمّل `items.product.images` فقط، بلا
/// `.user`)، فلا يصلنا اسم المتجر هنا. سطر واحد في الـ Backend يحلّها.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _CartAppBar(
        onClear: cartAsync.valueOrNull?.isEmpty == false
            ? () => _confirmClear(context, ref)
            : null,
      ),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _CartMessage(
          icon: Icons.cloud_off,
          title: 'تعذّر تحميل السلة',
          message: e.toString(),
          actionLabel: 'إعادة المحاولة',
          onAction: () => ref.read(cartProvider.notifier).refreshCart(),
        ),
        data: (cart) => cart.isEmpty
            ? _CartMessage(
                icon: Icons.shopping_cart_outlined,
                title: 'سلتك فارغة',
                message: 'تصفّح السوق وأضف القطع التي تحتاجها.',
                actionLabel: 'تصفّح السوق',
                onAction: () => context.go(AppRoutes.marketplace),
              )
            : _CartBody(cart: cart),
      ),
      bottomNavigationBar: cartAsync.maybeWhen(
        data: (cart) => cart.isEmpty ? null : _CartSummaryBar(cart: cart),
        orElse: () => null,
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تفريغ السلة'),
        content: const Text('سيتم حذف كل القطع من سلتك. لا يمكن التراجع.',
            style: AppTextStyles.bodySm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('تراجع'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('تفريغ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await ref.read(cartProvider.notifier).clear();
    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.showError(context, error);
    } else {
      AppSnackBar.showSuccess(context, 'تم تفريغ السلة.');
    }
  }
}

/// رأس بتدرّج كحلي أفقي وعنوان أخضر — مطابق لرأس 10_cart.html.
class _CartAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onClear;
  const _CartAppBar({this.onClear});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.onSecondaryFixed, AppColors.onTertiaryFixed],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_forward, color: AppColors.primaryFixedDim),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.marketplace),
      ),
      centerTitle: true,
      title: Text(
        'السلة',
        style: AppTextStyles.headlineLgMobile
            .copyWith(color: AppColors.primaryFixedDim),
      ),
      actions: [
        if (onClear != null)
          IconButton(
            tooltip: 'تفريغ السلة',
            onPressed: onClear,
            icon: const Icon(Icons.delete_sweep_outlined,
                color: AppColors.primaryFixedDim),
          ),
      ],
    );
  }
}

class _CartBody extends StatelessWidget {
  final Cart cart;
  const _CartBody({required this.cart});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.containerPadding),
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spaceM),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            boxShadow: AppDimensions.cardShadow,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.storefront_outlined,
                      color: AppColors.secondary),
                  const SizedBox(width: AppDimensions.spaceS),
                  const Text('قطع في سلتك', style: AppTextStyles.headlineMd),
                  const Spacer(),
                  Text(Formatters.itemCount(cart.totalQuantity),
                      style: AppTextStyles.labelSm),
                ],
              ),
              const Divider(color: AppColors.surfaceVariant, height: 24),
              for (var i = 0; i < cart.items.length; i++) ...[
                _CartItemTile(item: cart.items[i]),
                if (i != cart.items.length - 1)
                  const Divider(color: AppColors.surfaceVariant, height: 24),
              ],
            ],
          ),
        ),
        // مساحة تكفي الشريط السفلي الثابت.
        const SizedBox(height: 120),
      ],
    );
  }
}

/// سطر عنصر في السلة — صورة 80×80، الاسم، السعر، محدّد كمية، وحذف.
class _CartItemTile extends ConsumerStatefulWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  ConsumerState<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends ConsumerState<_CartItemTile> {
  bool _isBusy = false;

  Future<void> _run(Future<String?> Function() action) async {
    setState(() => _isBusy = true);
    final error = await action();
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (error != null) AppSnackBar.showError(context, error);
  }

  void _setQuantity(int value) {
    _run(() => ref
        .read(cartProvider.notifier)
        .setQuantity(itemId: widget.item.id, quantity: value));
  }

  Future<void> _remove() async {
    await _run(() => ref.read(cartProvider.notifier).removeItem(widget.item.id));
    if (mounted) {
      AppSnackBar.showSuccess(context, 'تم حذف القطعة من السلة.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    // لا نسمح بتجاوز المخزون المتاح؛ الخادم ينقص المخزون عند الشراء.
    final maxQuantity = item.product.stock > 0 ? item.product.stock : 1;

    return Opacity(
      opacity: _isBusy ? 0.5 : 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NetworkImageBox(
            url: item.product.primaryImageUrl,
            width: 80,
            height: 80,
            placeholderIconSize: 28,
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.product.title,
                        style: AppTextStyles.bodyMd,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'حذف',
                      visualDensity: VisualDensity.compact,
                      onPressed: _isBusy ? null : _remove,
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: AppColors.error),
                    ),
                  ],
                ),
                Text(
                  'سعر القطعة: ${Formatters.price(item.product.price)}',
                  style: AppTextStyles.labelSm,
                ),
                const SizedBox(height: AppDimensions.spaceS),
                Row(
                  children: [
                    Text(
                      Formatters.price(item.subtotal),
                      style: AppTextStyles.labelBold,
                    ),
                    const Spacer(),
                    _QuantityControl(
                      quantity: item.quantity,
                      max: maxQuantity,
                      enabled: !_isBusy,
                      onChanged: _setQuantity,
                    ),
                  ],
                ),
                if (item.quantity > item.product.stock &&
                    item.product.stock >= 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'المتوفّر الآن ${item.product.stock} فقط',
                      style:
                          AppTextStyles.labelSm.copyWith(color: AppColors.error),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// محدّد الكمية — حبّة رمادية بحدّ رفيع كما في التصميم.
class _QuantityControl extends StatelessWidget {
  final int quantity;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _QuantityControl({
    required this.quantity,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed:
                enabled && quantity < max ? () => onChanged(quantity + 1) : null,
            icon: const Icon(Icons.add, size: 18),
          ),
          Text('$quantity', style: AppTextStyles.bodySm),
          IconButton(
            visualDensity: VisualDensity.compact,
            // الكمية 1 لا تنقص إلى صفر: الخادم يشترط min:1، والحذف له زرّه.
            onPressed:
                enabled && quantity > 1 ? () => onChanged(quantity - 1) : null,
            icon: const Icon(Icons.remove, size: 18),
          ),
        ],
      ),
    );
  }
}

/// الشريط السفلي: الإجمالي الكلي بالأخضر + زر «إتمام الطلب».
class _CartSummaryBar extends StatelessWidget {
  final Cart cart;
  const _CartSummaryBar({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.surfaceVariant)),
        boxShadow: AppDimensions.bottomBarShadow,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('الإجمالي الكلي', style: AppTextStyles.bodySm),
                Text(
                  Formatters.price(cart.displayTotal),
                  style: AppTextStyles.headlineLgMobile
                      .copyWith(color: AppColors.primaryContainer),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.checkout),
              child: const Text('إتمام الطلب'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _CartMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textHint),
            const SizedBox(height: AppDimensions.spaceM),
            Text(title, style: AppTextStyles.headlineMd),
            const SizedBox(height: AppDimensions.spaceS),
            Text(message,
                textAlign: TextAlign.center, style: AppTextStyles.bodySm),
            const SizedBox(height: AppDimensions.spaceL),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
