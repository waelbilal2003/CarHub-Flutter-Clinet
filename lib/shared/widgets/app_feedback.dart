import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// مؤشّر تحميل يملأ الشاشة (يُستخدم في الحالات العامة).
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }
}

/// أدوات موحّدة لعرض رسائل النجاح والخطأ للمستخدم.
/// الرسائل تشرح ما حدث بوضوح ولا تعتذر ولا تكون غامضة.
class AppSnackBar {
  AppSnackBar._();

  static void showError(BuildContext context, String message) {
    _show(context, message, AppColors.error);
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppColors.success);
  }

  static void _show(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
