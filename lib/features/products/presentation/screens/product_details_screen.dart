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
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/review.dart';
import '../providers/product_provider.dart';
import '../providers/wishlist_provider.dart';

/// تفاصيل المنتج — GET /products/{id} (يعيد merchant و reviews[]).
///
/// مطابقة لـ 08_product_details.html في: صورة بطول كبير أعلى الشاشة،
/// بطاقة بيضاء تعلوها بزوايا علوية 24، السعر بحجم headline-xl فوق
/// الاسم، جدول صفوف مفصولة بحدود، ثم وصف، وشريط إجراءات سفلي ثابت
/// بزرّ أساسي بشكل حبّة.
///
/// ⚠️ تعارض التصميم مع الـ API (مسجّل لإسراء): جدول المواصفات في
/// التصميم يعرض «رقم القطعة (OE)» و«موديل السيارة» و«الحالة: جديد»
/// وشارة «متوافق مع سيارتك» — ولا يوجد أيٌّ من هذه الحقول في استجابة
/// المنتج. بنينا الجدول من الحقول الحقيقية المتاحة: المخزون، الحالة
/// (status_label)، البائع، وتاريخ الإضافة. وزر «طلب تركيب في ورشة»
/// حُذف لعدم وجود مسار له.
class ProductDetailsScreen extends ConsumerWidget {
  final int productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailsProvider(productId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(productDetailsProvider(productId)),
        ),
        data: (product) => _Content(product: product),
      ),
      bottomNavigationBar: productAsync.maybeWhen(
        data: (product) => _BottomActionBar(product: product),
        orElse: () => null,
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  final Product product;
  const _Content({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // زرّ القلب يظهر فقط عندما يعمل مسار المفضّلة في الخادم.
    final showFavorite = ref.watch(isWishlistAvailableProvider);
    final isFavorite = ref.watch(isFavoriteProvider(product.id));

    return CustomScrollView(
      slivers: [
        // الصورة البطلة مع زرّي رجوع ومفضّلة عائمين فوقها (كما في التصميم).
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: AppColors.surfaceContainerLow,
          foregroundColor: AppColors.onSecondaryFixed,
          leading: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceS),
            child: CircleAvatar(
              backgroundColor: AppColors.white.withValues(alpha: 0.85),
              child: IconButton(
                icon: const Icon(Icons.arrow_forward,
                    color: AppColors.onSecondaryFixed),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          actions: [
            if (showFavorite)
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spaceS),
                child: CircleAvatar(
                  backgroundColor: AppColors.white.withValues(alpha: 0.85),
                  child: IconButton(
                    tooltip:
                        isFavorite ? 'إزالة من المفضّلة' : 'إضافة للمفضّلة',
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? AppColors.error
                          : AppColors.onSecondaryFixed,
                    ),
                    onPressed: () async {
                      final error = await ref
                          .read(wishlistProvider.notifier)
                          .toggle(product);
                      if (error != null && context.mounted) {
                        AppSnackBar.showError(context, error);
                      }
                    },
                  ),
                ),
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: NetworkImageBox(
              url: product.primaryImageUrl,
              fit: BoxFit.contain,
              borderRadius: 0,
              placeholderIconSize: 72,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            transform: Matrix4.translationValues(0, -24, 0),
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.containerPadding,
              AppDimensions.spaceL,
              AppDimensions.containerPadding,
              AppDimensions.spaceXL,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.price(product.price),
                  style: AppTextStyles.headlineXl
                      .copyWith(color: AppColors.onSecondaryFixed),
                ),
                const SizedBox(height: AppDimensions.spaceS),
                Text(
                  product.title,
                  style: AppTextStyles.headlineLgMobile
                      .copyWith(color: AppColors.onSecondaryFixed),
                ),
                const SizedBox(height: AppDimensions.spaceM),
                _StockChip(product: product),
                const SizedBox(height: AppDimensions.spaceXL),

                const _SectionTitle(icon: Icons.tune, label: 'المواصفات'),
                const SizedBox(height: AppDimensions.spaceM),
                _SpecsTable(product: product),
                const SizedBox(height: AppDimensions.spaceXL),

                const _SectionTitle(label: 'التفاصيل'),
                const SizedBox(height: AppDimensions.spaceS),
                Text(
                  product.description.isEmpty
                      ? 'لم يضف التاجر وصفاً لهذه القطعة.'
                      : product.description,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppDimensions.spaceXL),

                _ReviewsSection(product: product),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// شارة التوفّر — بديل حقيقي لشارة «متوافق مع سيارتك» في التصميم.
class _StockChip extends StatelessWidget {
  final Product product;
  const _StockChip({required this.product});

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.isOutOfStock;
    final color = outOfStock ? AppColors.error : AppColors.onPrimaryFixedVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: outOfStock
            ? AppColors.errorContainer
            : AppColors.primaryFixed.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(outOfStock ? Icons.cancel : Icons.check_circle,
              size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            outOfStock
                ? 'غير متوفّر حالياً'
                : 'متوفّر — ${product.stock} في المخزون',
            style: AppTextStyles.labelBold.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData? icon;
  final String label;
  const _SectionTitle({this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.secondary),
          const SizedBox(width: AppDimensions.spaceS),
        ],
        Text(
          label,
          style: AppTextStyles.headlineMd
              .copyWith(color: AppColors.onSecondaryFixed),
        ),
      ],
    );
  }
}

/// جدول المواصفات — نفس شكل التصميم (إطار واحد، صفوف مفصولة بحدود،
/// التسمية رمادية على اليمين والقيمة غامقة على اليسار) لكن بحقول
/// موجودة فعلاً في الـ API.
class _SpecsTable extends StatelessWidget {
  final Product product;
  const _SpecsTable({required this.product});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, Widget)>[
      ('الكمية المتاحة', _valueText('${product.stock}')),
      if (product.displayStatus.isNotEmpty)
        ('حالة العرض', _valueText(product.displayStatus)),
      if (product.merchant != null)
        (
          'البائع',
          Text(
            product.merchant!.name,
            style: AppTextStyles.labelBold.copyWith(color: AppColors.primary),
          ),
        ),
      if (product.createdAt != null)
        ('أُضيفت في', _valueText(Formatters.date(product.createdAt))),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceBright,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceM),
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.surfaceVariant),
                      ),
              ),
              child: Row(
                children: [
                  Text(rows[i].$1, style: AppTextStyles.bodySm),
                  const Spacer(),
                  rows[i].$2,
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Widget _valueText(String value) => Text(
        value,
        style: AppTextStyles.labelBold
            .copyWith(color: AppColors.onSecondaryFixed),
      );
}

/// قسم التقييمات — يقرأ `product.reviews[]` ويسمح بإضافة تقييم عبر
/// POST /products/{id}/reviews.
class _ReviewsSection extends ConsumerWidget {
  final Product product;
  const _ReviewsSection({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final average = product.averageRating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionTitle(label: 'التقييمات'),
            const Spacer(),
            if (average != null) ...[
              const Icon(Icons.star_rounded,
                  color: AppColors.warning, size: 20),
              const SizedBox(width: 4),
              Text(
                '${average.toStringAsFixed(1)} (${product.reviews.length})',
                style: AppTextStyles.labelBold,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppDimensions.spaceM),
        if (product.reviews.isEmpty)
          const Text('لا توجد تقييمات لهذه القطعة بعد — كن أول المقيّمين.',
              style: AppTextStyles.bodySm)
        else
          for (final review in product.reviews) _ReviewTile(review: review),
        const SizedBox(height: AppDimensions.spaceM),
        OutlinedButton.icon(
          onPressed: () => _openReviewSheet(context, ref),
          icon: const Icon(Icons.rate_review_outlined),
          label: const Text('أضف تقييمك'),
        ),
      ],
    );
  }

  void _openReviewSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)),
      ),
      builder: (_) => _AddReviewSheet(productId: product.id),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceContainer,
            backgroundImage: review.user?.avatarUrl != null
                ? NetworkImage(review.user!.avatarUrl!)
                : null,
            child: review.user?.avatarUrl == null
                ? Text(review.user?.initial ?? '؟',
                    style: AppTextStyles.labelBold)
                : null,
          ),
          const SizedBox(width: AppDimensions.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(review.user?.name ?? 'مستخدم',
                        style: AppTextStyles.labelBold),
                    const Spacer(),
                    for (var i = 0; i < 5; i++)
                      Icon(
                        i < review.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                  ],
                ),
                if (review.comment != null) ...[
                  const SizedBox(height: 2),
                  Text(review.comment!, style: AppTextStyles.bodySm),
                ],
                const SizedBox(height: 2),
                Text(Formatters.date(review.createdAt),
                    style: AppTextStyles.labelSm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ورقة سفلية لإضافة تقييم — POST /products/{id}/reviews.
class _AddReviewSheet extends ConsumerStatefulWidget {
  final int productId;
  const _AddReviewSheet({required this.productId});

  @override
  ConsumerState<_AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends ConsumerState<_AddReviewSheet> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await ref.read(submitReviewProvider.notifier).submit(
          productId: widget.productId,
          rating: _rating,
          comment: _commentController.text,
        );
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
      AppSnackBar.showSuccess(context, 'تم إضافة تقييمك بنجاح.');
    } else {
      final error = ref.read(submitReviewProvider).error;
      AppSnackBar.showError(context, error ?? 'تعذّر إرسال التقييم.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(submitReviewProvider);

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
          const Text('تقييمك للقطعة', style: AppTextStyles.headlineMd),
          const SizedBox(height: AppDimensions.spaceM),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.warning,
                    size: 32,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceS),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'اكتب رأيك في القطعة (اختياري)',
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : _submit,
              child: state.isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : const Text('إرسال التقييم'),
            ),
          ),
        ],
      ),
    );
  }
}

/// شريط الإجراءات السفلي الثابت — زر «إضافة للسلة» بشكل حبّة كما في
/// التصميم. زر «طلب تركيب في ورشة» غير مرسوم: لا مسار له في الـ API.
class _BottomActionBar extends ConsumerStatefulWidget {
  final Product product;
  const _BottomActionBar({required this.product});

  @override
  ConsumerState<_BottomActionBar> createState() => _BottomActionBarState();
}

class _BottomActionBarState extends ConsumerState<_BottomActionBar> {
  int _quantity = 1;
  bool _isAdding = false;

  Future<void> _addToCart() async {
    setState(() => _isAdding = true);
    final error = await ref.read(cartProvider.notifier).addItem(
          productId: widget.product.id,
          quantity: _quantity,
        );
    if (!mounted) return;
    setState(() => _isAdding = false);

    if (error != null) {
      AppSnackBar.showError(context, error);
      return;
    }
    AppSnackBar.showSuccess(context, 'تمت إضافة القطعة إلى سلتك.');
  }

  @override
  Widget build(BuildContext context) {
    final outOfStock = widget.product.isOutOfStock;
    // لا نسمح بتجاوز المخزون المتاح؛ الخادم يرفضه أصلاً وهذا يوفّر
    // على المستخدم محاولة فاشلة.
    final maxQuantity = widget.product.stock;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.containerPadding,
        AppDimensions.spaceM,
        AppDimensions.containerPadding,
        AppDimensions.spaceM,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.surfaceVariant)),
        boxShadow: AppDimensions.bottomBarShadow,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (!outOfStock) ...[
              _QuantityStepper(
                quantity: _quantity,
                max: maxQuantity,
                onChanged: (value) => setState(() => _quantity = value),
              ),
              const SizedBox(width: AppDimensions.spaceM),
            ],
            Expanded(
              child: SizedBox(
                height: AppDimensions.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: outOfStock || _isAdding ? null : _addToCart,
                  icon: _isAdding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : const Icon(Icons.shopping_cart_outlined),
                  label: Text(outOfStock ? 'نفد المخزون' : 'إضافة للسلة'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// محدّد الكمية — نفس شكل التصميم في السلة (حبّة رمادية بحدّ رفيع).
class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final int max;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({
    required this.quantity,
    required this.max,
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
                quantity < max ? () => onChanged(quantity + 1) : null,
            icon: const Icon(Icons.add, size: 18),
          ),
          Text('$quantity', style: AppTextStyles.labelBold),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
            icon: const Icon(Icons.remove, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.textHint),
            const SizedBox(height: AppDimensions.spaceM),
            Text(message,
                textAlign: TextAlign.center, style: AppTextStyles.bodySm),
            const SizedBox(height: AppDimensions.spaceM),
            TextButton(
                onPressed: onRetry, child: const Text('إعادة المحاولة')),
            TextButton(
              onPressed: () => context.go(AppRoutes.marketplace),
              child: const Text('العودة للسوق'),
            ),
          ],
        ),
      ),
    );
  }
}
