import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

/// شاشة المساعد الذكي — placeholder مبدئي يفتح كـ overlay من
/// [FloatingAiButton]. منطق الذكاء الاصطناعي الفعلي يُبنى لاحقاً؛
/// هذه فقط نقطة التوسّع الجاهزة (المسار البصري + مكان الحوار).
class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusCard),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppDimensions.spaceL),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                child: const Icon(Icons.smart_toy_outlined,
                    color: AppColors.accent, size: 28),
              ),
              const SizedBox(height: AppDimensions.spaceM),
              Text('المساعد الذكي', style: AppTextStyles.headline),
              const SizedBox(height: AppDimensions.spaceS),
              Text(
                'هذه الميزة قيد التطوير — سيتمكن المساعد قريباً من مساعدتك '
                'في تصفّح قطع الغيار والمزادات والإجابة عن استفساراتك.',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: AppDimensions.spaceXL),
            ],
          ),
        );
      },
    );
  }
}
