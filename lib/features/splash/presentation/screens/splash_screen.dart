import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

/// شاشة البداية — مطابقة لـ `client_app/01_splash.html`.
///
/// التصميم: خلفية كحلية داكنة جداً (on-secondary-fixed = #0D1C32)، وخلفها
/// دائرة خضراء ضخمة مموّهة بشفافية 10%، ثم دائرة زجاجية 96px تحوي أيقونة
/// سيارة خضراء فاتحة، فالاسم، فالشعار النصي، ثم ثلاث نقاط نابضة.
///
/// الانتقال يتم عبر الراوتر تلقائياً بمجرد أن يعرف حالة المصادقة
/// (نتيجة GET /auth/me).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onSecondaryFixed,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // التوهج الأخضر خلف المحتوى (bg-primary-container opacity-10 blur).
          const _AmbientGlow(),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.containerPadding,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // الدائرة الزجاجية مع أيقونة السيارة.
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryContainer
                            .withValues(alpha: 0.15),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 48,
                    color: AppColors.primaryFixedDim,
                  ),
                ),
                const SizedBox(height: AppDimensions.stackMd),

                Text(
                  AppConstants.appName,
                  style: AppTextStyles.headlineXl.copyWith(
                    color: AppColors.surfaceContainerLowest,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppDimensions.sectionMargin),

                Text(
                  AppConstants.appTagline,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineLgMobile.copyWith(
                    color: AppColors.surfaceContainerLow,
                  ),
                ),
                const SizedBox(height: AppDimensions.sectionMargin),

                const _BouncingDots(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// دائرة خضراء ضخمة مموّهة تعطي إحساس التوهج خلف المحتوى.
class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 1.2;
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryContainer.withValues(alpha: 0.10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryContainer.withValues(alpha: 0.10),
              blurRadius: 120,
              spreadRadius: 40,
            ),
          ],
        ),
      ),
    );
  }
}

/// ثلاث نقاط خضراء تقفز بتأخير متتابع (animate-bounce في HTML).
class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // تأخير 0 / 150 / 300 مللي ثانية كما في التصميم.
            final delay = i * 0.17;
            final t = (_controller.value - delay) % 1.0;
            final offset = -8 * (1 - (2 * t - 1).abs()).clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(0, offset),
              child: child,
            );
          },
          child: Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}
