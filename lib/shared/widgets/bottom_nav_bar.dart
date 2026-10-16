import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

/// عنصر واحد في شريط التنقّل السفلي.
class BottomNavItem {
  final IconData icon;
  final String label;

  const BottomNavItem({required this.icon, required this.label});
}

/// شريط التنقّل السفلي العائم لتطبيق العميل — 5 عناصر ثابتة (الرئيسية،
/// المتجر، المزايدة، الرسائل، حسابي) مطابقة لمرجع HTML (24_profile.html).
/// المسارات غير المبنية بعد (المتجر/المزايدة/الرسائل) تُبلَّغ عبر
/// [onComingSoon] بدل التنقّل، حتى تُضاف لاحقاً بسهولة.
class BottomNavBar extends StatelessWidget {
  static const items = [
    BottomNavItem(icon: Icons.home_outlined, label: 'الرئيسية'),
    BottomNavItem(icon: Icons.storefront_outlined, label: 'المتجر'),
    BottomNavItem(icon: Icons.gavel_outlined, label: 'المزايدة'),
    BottomNavItem(icon: Icons.chat_bubble_outline, label: 'الرسائل'),
    BottomNavItem(icon: Icons.person_outline, label: 'حسابي'),
  ];

  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceS,
      ),
      // مطابق لـ 24_profile.html: خلفية بيضاء، زوايا علوية مستديرة،
      // وظل متجه للأعلى 0 -4px 20px rgba(10,25,47,0.05).
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: AppDimensions.bottomBarShadow,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusM),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = index == currentIndex;
            // النشط بالأخضر (primary)، والباقي بالرمادي الأزرق (secondary).
            final color =
                selected ? AppColors.primary : AppColors.secondary;
            return InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceS,
                  vertical: AppDimensions.spaceXS,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, color: color, size: 24),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: AppTextStyles.caption.copyWith(
                        color: color,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
