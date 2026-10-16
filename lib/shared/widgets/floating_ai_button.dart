import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/ai_assistant/presentation/screens/ai_assistant_screen.dart';

/// الزر العائم لفتح المساعد الذكي — يظهر في كل شاشات تطبيق العميل عبر
/// [ClientScaffold]. مطابق لمرجع HTML (13_my_orders.html): دائرة 56px
/// خضراء بأيقونة روبوت، ظل ناعم، ونبض خفيف مستمر (animate-pulse).
///
/// منطق الذكاء الاصطناعي غير مبني بعد — الضغط يفتح شاشة مبدئية فقط.
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

  void _openAssistant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiAssistantScreen(),
    );
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
