import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';

/// سطر إرشادي صغير أسفل حقل كلمة المرور في شاشة إنشاء الحساب.
///
/// لماذا هذا الشكل بالذات: وضع الشرط داخل عنوان الحقل
/// («كلمة المرور (8 أحرف على الأقل)») يُطيل العنوان ويزاحم النص
/// المُدخل، ويبقى ظاهراً حتى بعد استيفاء الشرط. والأسلوب المتعارف عليه
/// في التطبيقات الرسمية هو إرشاد حيّ أسفل الحقل يتغيّر مع الكتابة:
///
///   • قبل الكتابة  → رمادي محايد: يخبر بالشرط بلا لوم.
///   • أقل من الحد   → أحمر مع علامة تنبيه: تحذير واضح أثناء الكتابة.
///   • مستوفٍ للحد   → أخضر مع علامة صح: تأكيد فوري أن الشرط تحقّق.
///
/// بهذا يؤدي اللون الأخضر معناه الصحيح (تمّ)، لا مجرد لون زينة.
class PasswordHint extends StatelessWidget {
  /// النص الحالي في حقل كلمة المرور.
  final String value;

  const PasswordHint({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final length = value.length;
    final isEmpty = length == 0;
    final isValid = length >= Validators.minPasswordLength;

    final (IconData icon, Color color, String text) = switch (true) {
      _ when isEmpty => (
          Icons.info_outline,
          AppColors.textSecondary,
          'استخدم ${Validators.minPasswordLength} محارف على الأقل.',
        ),
      _ when isValid => (
          Icons.check_circle_outline,
          AppColors.primaryContainer,
          'كلمة مرور مقبولة.',
        ),
      _ => (
          Icons.error_outline,
          AppColors.error,
          'باقٍ ${Validators.minPasswordLength - length} محارف '
              'لتصبح كلمة المرور مقبولة.',
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(
        top: AppDimensions.spaceXS,
        right: AppDimensions.spaceXS,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.labelSm.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
