import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import 'app_feedback.dart';
import 'bottom_nav_bar.dart';
import 'floating_ai_button.dart';

/// غلاف موحّد حول [Scaffold] لكل شاشات تطبيق العميل بعد تسجيل الدخول.
/// يضيف تلقائياً:
///  - [FloatingAiButton] عائماً أسفل اليسار فوق المحتوى وفوق شريط
///    التنقّل (حاضر في كل شاشة، كما هو مطلوب).
///  - شريط تنقّل سفلي عند تمرير [navIndex] (شاشات المستوى الأعلى فقط؛
///    شاشات فرعية مثل تعديل الملف الشخصي تُمرَّر بلا navIndex فتختفي).
///
/// شاشات المصادقة (splash/login/register/otp) لا تُغلَّف بهذا الودجت
/// لأن المستخدم لم يسجّل دخوله بعد ولا يظهر فيها تنقّل أو مساعد ذكي.
class ClientScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final int? navIndex;
  final Color? backgroundColor;

  /// زر إجراء إضافي خاص بالشاشة (يُرسم أعلى الزر العائم للمساعد).
  final Widget? floatingActionButton;

  const ClientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.navIndex,
    this.backgroundColor,
    this.floatingActionButton,
  });

  void _onNavTap(BuildContext context, int index) {
    if (index == navIndex) return;
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.marketplace);
        break;
      case 2:
        context.go(AppRoutes.tenders);
        break;
      case 3:
        context.go(AppRoutes.chats);
        break;
      case 4:
        context.go(AppRoutes.profile);
        break;
      default:
        AppSnackBar.showSuccess(context, 'هذه الميزة قادمة قريباً على CarHub.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor ?? AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          body,
          Positioned(
            left: 16,
            bottom: navIndex != null ? 96 : 24,
            child: const FloatingAiButton(),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: navIndex != null
          ? BottomNavBar(
              currentIndex: navIndex!,
              onTap: (index) => _onNavTap(context, index),
            )
          : null,
    );
  }
}
