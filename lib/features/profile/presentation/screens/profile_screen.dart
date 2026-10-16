import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../../shared/widgets/client_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// الملف الشخصي — مطابق لـ `client_app/24_profile.html`.
///
/// التصميم: رأس بتدرّج كحلي (135°, #0A192F → #112A4F) بزوايا سفلية كبيرة،
/// وبداخله الصورة الدائرية بإطار أبيض وزر تعديل أخضر، ثم الاسم وتاريخ
/// الانضمام وزر «تعديل الملف الشخصي» شبه شفاف. تحته بطاقة بيضاء واحدة
/// (نصف قطر 16px + ظل ناعم) تضم قائمة الأقسام، ثم زر خروج أحمر خفيف.
///
/// الربط: البيانات من GET /auth/me، والصورة عبر POST /auth/profile.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _pickAndUploadAvatar(
      BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final success = await ref
        .read(profileControllerProvider.notifier)
        .uploadAvatar(picked.path);

    if (!context.mounted) return;
    if (success) {
      AppSnackBar.showSuccess(context, 'تم تحديث الصورة.');
    } else {
      final err =
          ref.read(profileControllerProvider).error ?? 'تعذّر رفع الصورة.';
      AppSnackBar.showError(context, err);
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج',
                style: TextStyle(color: AppColors.errorColor)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isUploading = ref.watch(profileControllerProvider).isLoading;

    if (user == null) {
      return const ClientScaffold(
        navIndex: 4,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ClientScaffold(
      navIndex: 4,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── الرأس الكحلي المتدرّج ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.containerPadding,
              64,
              AppDimensions.containerPadding,
              48,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppColors.navyGradientStart,
                  AppColors.navyGradientEnd,
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(AppDimensions.radiusXL),
              ),
            ),
            child: Column(
              children: [
                // الصورة + زر تغييرها.
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.surfaceColor, width: 4),
                          image: user.avatarUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(user.avatarUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: AppColors.surfaceContainerHigh,
                        ),
                        child: user.avatarUrl == null
                            ? const Icon(Icons.person,
                                size: 44, color: AppColors.outline)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: InkWell(
                          onTap: isUploading
                              ? null
                              : () => _pickAndUploadAvatar(context, ref),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.surfaceColor, width: 2),
                            ),
                            child: isUploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              AppColors.white),
                                    ),
                                  )
                                : const Icon(Icons.edit,
                                    size: 16, color: AppColors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.stackSm),

                Text(
                  user.name,
                  style: AppTextStyles.headlineLgMobile
                      .copyWith(color: AppColors.white),
                ),
                if (user.createdAt != null)
                  Text(
                    'عضو منذ ${user.createdAt!.year}',
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.tertiaryFixedDim),
                  ),
                const SizedBox(height: AppDimensions.stackSm),

                // زر شبه شفاف على الرأس الداكن.
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.editProfile),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    backgroundColor:
                        AppColors.surfaceContainer.withValues(alpha: 0.20),
                    side: BorderSide(
                      color:
                          AppColors.surfaceContainer.withValues(alpha: 0.30),
                    ),
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.stackLg),
                  ),
                  child: const Text('تعديل الملف الشخصي'),
                ),
              ],
            ),
          ),

          // ── قائمة الأقسام ──
          Padding(
            padding: const EdgeInsets.all(AppDimensions.containerPadding),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusCard),
                    border:
                        Border.all(color: AppColors.surfaceContainerLow),
                    boxShadow: AppDimensions.cardShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _MenuRow(
                        icon: Icons.gavel_outlined,
                        label: 'مناقصاتي',
                        onTap: () => context.push(AppRoutes.tenders),
                      ),
                      const Divider(height: 1),
                      _MenuRow(
                        icon: Icons.chat_bubble_outline,
                        label: 'الرسائل',
                        onTap: () => context.push(AppRoutes.chats),
                      ),
                      const Divider(height: 1),
                      _MenuRow(
                        icon: Icons.location_on_outlined,
                        label: 'عناوين الشحن',
                        onTap: () => context.push(AppRoutes.addresses),
                      ),
                      const Divider(height: 1),
                      _MenuRow(
                        icon: Icons.mail_outline,
                        label: user.email,
                        onTap: null,
                      ),
                      const Divider(height: 1),
                      _MenuRow(
                        icon: Icons.phone_outlined,
                        label: user.phone ?? 'لم يُضف رقم هاتف',
                        onTap: null,
                      ),
                      const Divider(height: 1),
                      // لا نعرض «نوع الحساب»: كل مستخدمي هذا التطبيق
                      // عملاء، فالسطر لا يضيف معلومة. نعرض بدله تاريخ
                      // الانضمام القادم فعلاً من الخادم (created_at).
                      _MenuRow(
                        icon: Icons.event_outlined,
                        label: user.createdAt == null
                            ? 'عضو في CarHub'
                            : 'عضو منذ ${Formatters.date(user.createdAt)}',
                        onTap: null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.stackMd),

                // زر تسجيل الخروج — خلفية حمراء خفيفة كما في التصميم.
                InkWell(
                  onTap: () => _confirmLogout(context, ref),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusCard),
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(AppDimensions.stackMd),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer.withValues(alpha: 0.35),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(
                        color:
                            AppColors.errorContainer.withValues(alpha: 0.60),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout,
                            size: 20, color: AppColors.errorColor),
                        const SizedBox(width: AppDimensions.stackSm),
                        Text('تسجيل الخروج',
                            style: AppTextStyles.labelBold
                                .copyWith(color: AppColors.errorColor)),
                      ],
                    ),
                  ),
                ),

                // مساحة تحت الزر العائم وشريط التنقّل.
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// صف في قائمة الأقسام — أيقونة دائرية + عنوان + سهم.
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _MenuRow({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer.withValues(alpha: 0.30),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.onSecondaryContainer),
      ),
      title: Text(label, style: AppTextStyles.bodyLg),
      trailing: onTap == null
          ? null
          : const Icon(Icons.chevron_left, color: AppColors.outlineVariant),
    );
  }
}
