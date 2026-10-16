import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';

/// شارة حالة صغيرة بشكل حبّة (pill) — تُستخدم لعرض حالة مناقصة/طلب
/// (نشط، منتهي، قيد الانتظار...). اللون يُمرَّر من الاستدعاء لأن كل
/// حالة لها لونها الخاص (النجاح أخضر، الانتهاء رمادي، الخطأ أحمر...).
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
