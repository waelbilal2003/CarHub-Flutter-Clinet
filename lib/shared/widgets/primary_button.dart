import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// زر أساسي موحّد. يدعم:
///  - [isLoading]: يعرض مؤشّر تحميل ويعطّل الضغط تلقائياً.
///  - [onPressed]: عند null يظهر الزر معطّلاً.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      // نمنع الضغط أثناء التحميل
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            )
          : Text(label),
    );
  }
}
