import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/network_image_box.dart';
import '../../domain/entities/ai_reply.dart';

/// عناصر شاشة المساعد — مطابقة لـ 23_ai_assistant.html.

const _bubbleRadius = Radius.circular(12);

/// فقاعة العميل: خضراء (primary-container) مع أفاتار على الطرف الآخر.
class UserBubble extends StatelessWidget {
  final String text;
  const UserBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.75),
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.only(
                topLeft: _bubbleRadius,
                topRight: _bubbleRadius,
                bottomRight: _bubbleRadius,
              ),
            ),
            child: Text(text,
                style: AppTextStyles.bodyMd
                    .copyWith(color: AppColors.onPrimaryContainer)),
          ),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.surfaceContainerHigh,
          child: Icon(Icons.person, size: 18, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// أفاتار المساعد الصغير بجانب ردوده.
class AssistantAvatar extends StatelessWidget {
  const AssistantAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: const Icon(Icons.smart_toy, size: 18, color: AppColors.primary),
    );
  }
}

/// فقاعة نص المساعد: بيضاء بحدّ وظل ناعم.
class AssistantTextBubble extends StatelessWidget {
  final String text;
  final Color? background;
  final Color? borderColor;
  final Widget? trailing;

  const AssistantTextBubble({
    super.key,
    required this.text,
    this.background,
    this.borderColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: background ?? AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: _bubbleRadius,
          topRight: _bubbleRadius,
          bottomLeft: _bubbleRadius,
        ),
        border: Border.all(color: borderColor ?? AppColors.surfaceVariant),
        boxShadow: AppDimensions.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: AppTextStyles.bodyMd),
          if (trailing != null) ...[
            const SizedBox(height: AppDimensions.spaceS),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// بطاقة منتج داخل المحادثة: صورة، عنوان، سعر وعملة، متجر ومدينة، شارة توافق.
class AiProductCard extends StatelessWidget {
  final AiProduct product;
  final VoidCallback onTap;

  const AiProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final store = [product.merchantName, product.city]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' · ');

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(AppDimensions.spaceS),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NetworkImageBox(
                url: product.imageUrl,
                width: double.infinity,
                height: 96,
                borderRadius: AppDimensions.radiusS,
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Text(product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelBold),
              const SizedBox(height: AppDimensions.spaceXS),
              Text('${product.price} ${product.currency}',
                  style: AppTextStyles.labelBold
                      .copyWith(color: AppColors.primary)),
              if (store.isNotEmpty)
                Text(store,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm),
              const SizedBox(height: AppDimensions.spaceS),
              CompatibilityBadge(product.compatibility),
            ],
          ),
        ),
      ),
    );
  }
}

/// exact ← «متوافق» (أخضر)، partial ← «تأكد من التوافق» (كهرماني).
class CompatibilityBadge extends StatelessWidget {
  final AiCompatibility compatibility;
  const CompatibilityBadge(this.compatibility, {super.key});

  @override
  Widget build(BuildContext context) {
    final exact = compatibility == AiCompatibility.exact;
    final color = exact ? AppColors.primary : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(exact ? Icons.check_circle : Icons.info_outline,
              size: 14, color: color),
          const SizedBox(width: 4),
          Text(exact ? 'متوافق' : 'تأكد من التوافق',
              style: AppTextStyles.labelSm.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// بطاقة إجراء ذكية (Carousel في التصميم): أيقونة دائرية، عنوان، زر.
class AiActionCard extends StatelessWidget {
  final AiCard card;
  final VoidCallback onPressed;

  const AiActionCard({super.key, required this.card, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color iconBg, String button, bool primary) =
        switch (card) {
      OpenProductCard() => (
          Icons.shopping_cart_outlined,
          AppColors.secondaryContainer,
          'تسوق الآن',
          true
        ),
      OpenMarketplaceSearchCard() => (
          Icons.search,
          AppColors.secondaryContainer,
          'ابحث في السوق',
          true
        ),
      CreateTenderCard() => (
          Icons.gavel,
          AppColors.errorContainer.withValues(alpha: 0.3),
          'اطلب عروض أسعار',
          false
        ),
    };

    return Container(
      width: 240,
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: AppDimensions.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primaryContainer),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(card.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelBold),
          const SizedBox(height: AppDimensions.spaceM),
          SizedBox(
            width: double.infinity,
            child: primary
                ? _GradientButton(label: button, onPressed: onPressed)
                : OutlinedButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: Text(button, style: AppTextStyles.labelBold),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onSurface,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      side: const BorderSide(color: AppColors.outlineVariant),
                      shape: const StadiumBorder(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _GradientButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF00B761), Color(0xFF009951)]),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.onPrimary,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppTextStyles.button),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_back, size: 16),
          ],
        ),
      ),
    );
  }
}

/// مؤشّر «يكتب...» بثلاث نقاط نابضة.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('المساعد يكتب', style: AppTextStyles.bodySm),
        const SizedBox(width: 6),
        ...List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final t = (_c.value - i * 0.2) % 1.0;
              final opacity = t < 0.5 ? 0.3 + t * 1.4 : 1.0 - (t - 0.5) * 1.4;
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: opacity.clamp(0.3, 1.0)),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ],
    );
  }
}
