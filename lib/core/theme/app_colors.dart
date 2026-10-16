import 'package:flutter/material.dart';

/// لوحة ألوان CarHub — منقولة حرفياً من `_design/DESIGN.md`.
///
/// القسم الأول: رموز نظام Material 3 كما وردت في الـ front-matter للتصميم
/// (وهي نفسها المستخدمة في ملفات Stitch HTML عبر tailwind.config).
/// القسم الثاني: أسماء دلالية مختصرة تستخدمها الشاشات، وكلها تشير إلى
/// نفس القيم أعلاه — فلا يوجد لون مخترَع في المشروع.
class AppColors {
  AppColors._();

  // ─────────── رموز التصميم (Material 3) ───────────
  static const Color primary = Color(0xFF006D37);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// الأخضر الحيوي (#00B761) — لون الأزرار الأساسية ونقاط التحويل.
  static const Color primaryContainer = Color(0xFF00B761);
  static const Color onPrimaryContainer = Color(0xFF00401E);
  static const Color primaryFixed = Color(0xFF6DFE9E);
  static const Color primaryFixedDim = Color(0xFF4DE085);
  static const Color onPrimaryFixed = Color(0xFF00210D);
  static const Color onPrimaryFixedVariant = Color(0xFF005228);
  static const Color inversePrimary = Color(0xFF4DE085);

  static const Color secondary = Color(0xFF515F78);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD2E0FE);
  static const Color onSecondaryContainer = Color(0xFF55637D);
  static const Color secondaryFixed = Color(0xFFD6E3FF);
  static const Color secondaryFixedDim = Color(0xFFB9C7E4);

  /// كحلي داكن جداً — خلفية شاشة البداية (01_splash).
  static const Color onSecondaryFixed = Color(0xFF0D1C32);
  static const Color onSecondaryFixedVariant = Color(0xFF39475F);

  static const Color tertiary = Color(0xFF555F6F);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF96A0B2);
  static const Color onTertiaryContainer = Color(0xFF2D3746);
  static const Color tertiaryFixed = Color(0xFFD9E3F7);
  static const Color tertiaryFixedDim = Color(0xFFBDC7DA);
  static const Color onTertiaryFixed = Color(0xFF121C2A);
  static const Color onTertiaryFixedVariant = Color(0xFF3D4757);

  static const Color errorColor = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color surfaceColor = Color(0xFFF7F9FC);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color surfaceDim = Color(0xFFD8DADD);
  static const Color surfaceBright = Color(0xFFF7F9FC);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F7);
  static const Color surfaceContainer = Color(0xFFECEEF1);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EB);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E6);
  static const Color onSurfaceVariant = Color(0xFF3D4A3E);

  static const Color outline = Color(0xFF6D7B6D);
  static const Color outlineVariant = Color(0xFFBCCABB);

  /// القبة الداكنة أعلى شاشة تسجيل الدخول (02_login).
  static const Color inverseSurface = Color(0xFF2D3133);
  static const Color onInverseSurface = Color(0xFFEFF1F4);
  static const Color surfaceTint = Color(0xFF006D37);

  /// تدرّج الرأس الكحلي في شاشة الملف الشخصي (24_profile):
  /// `linear-gradient(135deg, #0A192F 0%, #112A4F 100%)`
  static const Color navyGradientStart = Color(0xFF0A192F);
  static const Color navyGradientEnd = Color(0xFF112A4F);

  // ─────────── أسماء دلالية تستخدمها الشاشات ───────────
  // كلها إشارات إلى الرموز أعلاه — لا قيمة جديدة هنا إطلاقاً.

  /// الكحلي العميق (#0A192F) — الرؤوس والحاويات عالية المستوى.
  static const Color navy = navyGradientStart;

  /// الأخضر الأساسي للأزرار والإجراءات (#00B761).
  static const Color accent = primaryContainer;
  static const Color accentDark = primary;
  static const Color accentLight = primaryFixedDim;

  static const Color background = surfaceColor;
  static const Color surface = surfaceContainerLowest;
  static const Color surfaceAlt = surfaceContainerLow;

  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textHint = outline;

  static const Color success = primaryContainer;
  static const Color error = errorColor;
  static const Color warning = Color(0xFFE3A008);

  static const Color border = outlineVariant;
  static const Color divider = surfaceContainerLow;

  /// رمز `surface-variant` في DESIGN.md (#e0e3e6) — نفس قيمة
  /// [surfaceContainerHighest]. تستخدمه شاشات السوق لحدود الجداول
  /// والفواصل بين صفوف البطاقات، كما في ملفات Stitch (`border-surface-variant`).
  static const Color surfaceVariant = surfaceContainerHighest;

  static const Color white = Color(0xFFFFFFFF);
}
