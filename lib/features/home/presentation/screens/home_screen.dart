import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../../shared/widgets/client_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// الشاشة الرئيسية — نقطة الوصول بعد الدخول.
/// تعرض ترحيباً، بطاقات وصول سريع لأقسام CarHub، ومدخلاً للملف
/// الشخصي (لا مناقصات ولا سوق حقيقي بعد — خارج نطاق المرحلة الأولى).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _comingSoon(BuildContext context) {
    AppSnackBar.showSuccess(context, 'هذه الميزة قادمة قريباً على CarHub.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return ClientScaffold(
      navIndex: 0,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.containerPadding,
                AppDimensions.containerPadding,
                AppDimensions.containerPadding,
                120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    userName: user?.name,
                    onProfileTap: () => context.push(AppRoutes.profile),
                  ),
                  const SizedBox(height: AppDimensions.spaceL),
                  _SearchBar(onTap: () => _comingSoon(context)),
                  const SizedBox(height: AppDimensions.spaceXL),
                  Text('كل ما تحتاجه', style: AppTextStyles.title),
                  const SizedBox(height: AppDimensions.spaceM),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: AppDimensions.spaceM,
                    crossAxisSpacing: AppDimensions.spaceM,
                    childAspectRatio: 1.25,
                    children: [
                      _QuickActionCard(
                        icon: Icons.storefront_outlined,
                        label: 'سوق قطع الغيار',
                        color: AppColors.primary,
                        onTap: () => context.go(AppRoutes.marketplace),
                      ),
                      _QuickActionCard(
                        icon: Icons.gavel_outlined,
                        label: 'المناقصات',
                        color: AppColors.accent,
                        onTap: () => context.push(AppRoutes.tenders),
                      ),
                      _QuickActionCard(
                        icon: Icons.chat_bubble_outline,
                        label: 'الرسائل',
                        color: AppColors.accent,
                        onTap: () => context.push(AppRoutes.chats),
                      ),
                      _QuickActionCard(
                        icon: Icons.smart_toy_outlined,
                        label: 'مساعد ذكي',
                        color: AppColors.primary,
                        onTap: () => _comingSoon(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceXL),

                  // بطاقة الملف الشخصي
                  _ActionCard(
                    icon: Icons.person_outline,
                    title: 'الملف الشخصي',
                    subtitle: 'اعرض بياناتك وحدّثها',
                    onTap: () => context.push(AppRoutes.profile),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? userName;
  final VoidCallback onProfileTap;

  const _Header({required this.userName, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('أهلاً بك 👋', style: AppTextStyles.bodySecondary),
              const SizedBox(height: 2),
              Text(userName ?? 'عزيزي العميل', style: AppTextStyles.headline),
            ],
          ),
        ),
        InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.spaceS),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.person_outline, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceM,
          vertical: AppDimensions.spaceM,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textHint),
            const SizedBox(width: AppDimensions.spaceS),
            Text('ابحث عن قطعة أو موديل...',
                style: AppTextStyles.body.copyWith(color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceS),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            Text(label, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppDimensions.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.title),
                  Text(subtitle, style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
