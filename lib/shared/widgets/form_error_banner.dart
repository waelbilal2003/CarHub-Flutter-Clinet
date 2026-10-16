import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

/// شريط خطأ ثابت داخل النموذج.
///
/// أفضل من SnackBar وحده في شاشات المصادقة: الرسالة تبقى معروضة أمام
/// المستخدم حتى يصحّح المشكلة، ولا تختفي بعد ثوانٍ.
class FormErrorBanner extends StatelessWidget {
  final String? message;

  const FormErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppDimensions.stackMd),
      padding: const EdgeInsets.all(AppDimensions.stackMd),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
        border: Border.all(color: AppColors.errorContainer),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline,
              size: 20, color: AppColors.onErrorContainer),
          const SizedBox(width: AppDimensions.stackSm),
          Expanded(
            child: Text(
              message!,
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
