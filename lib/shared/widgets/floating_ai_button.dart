import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';

/// الزر العائم لفتح المساعد الذكي — يظهر في كل شاشات تطبيق العميل عبر
/// [ClientScaffold]. مطابق لمرجع HTML (13_my_orders.html): دائرة 56px
/// خضراء بأيقونة روبوت، ظل ناعم، ونبض خفيف مستمر (animate-pulse).
///
/// الضغط يفتح شاشة المساعد ([AppRoutes.aiAssistant]).
class FloatingAiButton extends StatefulWidget {
  const FloatingAiButton({super.key});

  @override
  State<FloatingAiButton> createState() => _FloatingAiButtonState();
}

class _FloatingAiButtonState extends State<FloatingAiButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // نبض بطيء مستمر يقابل CSS: animate-pulse (2s ease-in-out infinite)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// شاشة كاملة كما في 23_ai_assistant (رأس كحلي وزر رجوع)، لا ورقة سفلية.
  void _openAssistant(BuildContext context) {
    context.push(AppRoutes.aiAssistant);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.6).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openAssistant(context),
          customBorder: const CircleBorder(),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
