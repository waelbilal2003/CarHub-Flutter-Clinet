import 'package:flutter/material.dart';
import 'app_colors.dart';

/// نظام الخطوط — منقول حرفياً من `_design/DESIGN.md`.
///
/// الخط: **Readex Pro** (مضمّن محلياً في assets/fonts كخط متغيّر،
/// ومسجَّل في pubspec.yaml — لا اعتماد على الإنترنت).
///
/// المقاييس كما في التصميم (الحجم / الوزن / ارتفاع السطر بالبكسل):
///   headline-xl        32 / 700 / 48
///   headline-lg        24 / 700 / 36
///   headline-lg-mobile 22 / 700 / 32
///   headline-md        20 / 600 / 30
///   body-lg            18 / 400 / 28
///   body-md            16 / 400 / 24
///   body-sm            14 / 400 / 20
///   label-bold         14 / 600 / 20
///   label-sm           12 / 500 / 16
class AppTextStyles {
  AppTextStyles._();

  /// يجب أن يطابق اسم العائلة المسجَّل في pubspec.yaml.
  static const String fontFamily = 'Readex Pro';

  // ─────────── مقاييس التصميم الرسمية ───────────

  static const TextStyle headlineXl = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 48 / 32,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 36 / 24,
    color: AppColors.onSurface,
  );

  /// النسخة المخصّصة للهاتف من العنوان الكبير (تُستخدم في otp/profile).
  static const TextStyle headlineLgMobile = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 32 / 22,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 30 / 20,
    color: AppColors.onSurface,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 28 / 18,
    color: AppColors.onSurface,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.onSurface,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.onSurfaceVariant,
  );

  static const TextStyle labelBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    color: AppColors.onSurface,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    color: AppColors.onSurfaceVariant,
  );

  // ─────────── أسماء دلالية تستخدمها الشاشات ───────────
  // إشارات إلى المقاييس أعلاه حتى لا تتكرّر القيم في مكانين.

  static const TextStyle displayLarge = headlineXl;
  static const TextStyle headline = headlineLg;
  static const TextStyle title = headlineMd;
  static const TextStyle body = bodyMd;
  static const TextStyle bodySecondary = bodySm;
  static const TextStyle caption = labelSm;

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    color: AppColors.white,
  );

  static const TextStyle link = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    color: AppColors.primaryContainer,
  );
}
