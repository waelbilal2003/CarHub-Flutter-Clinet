import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../../shared/widgets/network_image_box.dart';
import '../../domain/entities/product.dart';
import '../providers/wishlist_provider.dart';

/// بطاقة منتج في شبكة السوق — مطابقة لبطاقة 07_marketplace.html:
/// خلفية بيضاء، نصف قطر 16، حشوة 12، حدّ رمادي فاتح، وظل
/// `0 4px 20px rgba(10,25,47,0.05)`؛ ثم صورة مربّعة وفوقها زر قلب
/// المفضّلة، شارة حالة، عنوان سطرين، اسم المتجر بأيقونة، وسعر أخضر
/// بحجم headline-md تليه «ر.س» بحجم label-sm.
///
/// اختلاف واحد باقٍ عن التصميم: شارة «متوافق / غير متوافق» — لا يوجد
/// في الـ API أي حقل توافق مع سيارة المستخدم، فوضعنا مكانها حالة
/// المخزون الحقيقية بدل شارة مخترعة.
class ProductGridCard extends ConsumerWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductGridCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // زرّ القلب يظهر فقط عندما يعمل مسار المفضّلة في الخادم.
    final showFavorite = ref.watch(isWishlistAvailableProvider);
    final isFavorite = ref.watch(isFavoriteProvider(product.id));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          border: Border.all(color: AppColors.surfaceContainerHighest),
          boxShadow: AppDimensions.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: NetworkImageBox(
                      url: product.primaryImageUrl,
                      placeholderIconSize: 36,
                    ),
                  ),
                  // زر المفضّلة أعلى يسار الصورة كما في التصميم.
                  if (showFavorite)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: _FavoriteButton(
                        isFavorite: isFavorite,
                        onTap: () async {
                          final error = await ref
                              .read(wishlistProvider.notifier)
                              .toggle(product);
                          if (error != null && context.mounted) {
                            AppSnackBar.showError(context, error);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            _StockBadge(product: product),
            const SizedBox(height: AppDimensions.spaceXS),
            Text(
              product.title,
              style: AppTextStyles.labelBold.copyWith(height: 1.25),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (product.merchant != null) ...[
              const SizedBox(height: AppDimensions.spaceXS),
              Row(
                children: [
                  const Icon(Icons.storefront_outlined,
                      size: 14, color: AppColors.tertiary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      product.merchant!.name,
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColors.tertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppDimensions.spaceS),
            // السعر: الرقم بالأخضر الحيوي، والعملة أصغر بجانبه —
            // كما في التصميم (baseline واحد).
            Row(
              textBaseline: TextBaseline.alphabetic,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              children: [
                Text(
                  Formatters.number(product.price),
                  style: AppTextStyles.headlineMd
                      .copyWith(color: AppColors.primaryContainer),
                ),
                const SizedBox(width: 4),
                const Text('ر.س', style: AppTextStyles.labelSm),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// زر القلب — دائرة بيضاء شبه شفافة بظل خفيف، كما في التصميم.
/// القلب ممتلئ وأحمر عند الإضافة للمفضّلة، ومفرّغ رمادي عدا ذلك.
class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _FavoriteButton({required this.isFavorite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.8),
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 16,
            color: isFavorite ? AppColors.error : AppColors.secondary,
          ),
        ),
      ),
    );
  }
}

/// شارة صغيرة فوق العنوان — نفس شكل شارة «متوافق» في التصميم
/// (حدّ رفيع، زوايا 6، نص 10-12) لكن بمحتوى حقيقي من الـ API.
class _StockBadge extends StatelessWidget {
  final Product product;
  const _StockBadge({required this.product});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (product) {
      final p when p.isOutOfStock => ('نفد المخزون', AppColors.error),
      final p when p.isLowStock => ('باقٍ ${p.stock}', AppColors.warning),
      _ => (product.displayStatus, AppColors.onSurfaceVariant),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(fontSize: 10, color: color),
      ),
    );
  }
}
