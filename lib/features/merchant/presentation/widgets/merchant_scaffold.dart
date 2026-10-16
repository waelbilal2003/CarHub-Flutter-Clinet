import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

/// غلاف موحّد لشاشات تطبيق الأعمال (التاجر).
///
/// يختلف عن [ClientScaffold] الخاص بالعميل عمداً، مطابقةً لتصاميم
/// business_app:
///  • الرأس خلفيته `surface-container-highest` لا تدرّج كحلي،
///    واسم التطبيق فيه أخضر في الوسط.
///  • شريط سفلي بأربعة عناصر (الرئيسية، المناقصات، المخزون، الطلبات)
///    لا خمسة، وبلا زر مساعد ذكي عائم.
class MerchantScaffold extends StatelessWidget {
  final Widget body;
  final String title;

  /// موضع الشاشة في الشريط السفلي (null = شاشة فرعية بلا شريط).
  final int? navIndex;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const MerchantScaffold({
    super.key,
    required this.body,
    required this.title,
    this.navIndex,
    this.actions,
    this.floatingActionButton,
  });

  static const _items = [
    (Icons.dashboard_outlined, 'الرئيسية', AppRoutes.merchantDashboard),
    (Icons.gavel_outlined, 'المناقصات', AppRoutes.tenders),
    (Icons.inventory_2_outlined, 'المخزون', AppRoutes.inventory),
    (Icons.receipt_long_outlined, 'الطلبات', AppRoutes.merchantOrders),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: navIndex == null,
        title: Text(
          title,
          style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary),
        ),
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: navIndex == null
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                boxShadow: AppDimensions.bottomBarShadow,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusM),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceM,
                    vertical: AppDimensions.spaceS,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        _NavItem(
                          icon: _items[i].$1,
                          label: _items[i].$2,
                          isSelected: i == navIndex,
                          onTap: () {
                            if (i == navIndex) return;
                            context.go(_items[i].$3);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.secondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceS,
          vertical: AppDimensions.spaceXS,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
