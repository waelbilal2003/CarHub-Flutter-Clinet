import 'package:flutter/material.dart';

/// المسافات وأنصاف الأقطار — منقولة من `_design/DESIGN.md`.
/// النظام مبني على شبكة 8pt.
class AppDimensions {
  AppDimensions._();

  // ─────────── المسافات (spacing في التصميم) ───────────
  static const double base = 8.0;
  static const double stackSm = 8.0;
  static const double stackMd = 16.0;
  static const double stackLg = 24.0;
  static const double cardGap = 16.0;
  static const double sectionMargin = 32.0;

  /// هامش جانبي للمحتوى (container-padding في التصميم) = 20px.
  static const double containerPadding = 20.0;

  // أسماء مختصرة تستخدمها الشاشات (نفس القيم أعلاه).
  static const double spaceXS = 4.0;
  static const double spaceS = stackSm;
  static const double spaceM = stackMd;
  static const double spaceL = stackLg;
  static const double spaceXL = sectionMargin;
  static const double spaceXXL = 48.0;

  // ─────────── أنصاف الأقطار ───────────
  /// نصف القطر القياسي لبطاقات المحتوى = 16px.
  static const double radiusCard = 16.0;

  /// حقول الإدخال = 8px (Input Fields في التصميم).
  static const double radiusInput = 8.0;

  /// شكل الحبّة الكامل — للأزرار الأساسية وشريط البحث حصراً.
  static const double radiusPill = 999.0;

  // أسماء مختصرة متوافقة مع الكود الحالي.
  static const double radiusS = radiusInput;
  static const double radiusM = 12.0;
  static const double radiusL = radiusCard;
  static const double radiusXL = 24.0;

  // ─────────── الظلال ───────────
  /// ظل البطاقة القياسي: `0px 4px 20px rgba(10, 25, 47, 0.05)`
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0D0A192F),
      offset: Offset(0, 4),
      blurRadius: 20,
    ),
  ];

  /// النسخة الأقوى المستخدمة في بطاقة تسجيل الدخول (شفافية 0.1).
  static const List<BoxShadow> cardShadowStrong = [
    BoxShadow(
      color: Color(0x1A0A192F),
      offset: Offset(0, 4),
      blurRadius: 20,
    ),
  ];

  /// ظل شريط التنقّل السفلي: `0 -4px 20px rgba(10,25,47,0.05)`
  static const List<BoxShadow> bottomBarShadow = [
    BoxShadow(
      color: Color(0x0D0A192F),
      offset: Offset(0, -4),
      blurRadius: 20,
    ),
  ];

  // ─────────── ارتفاعات العناصر ───────────
  /// ارتفاع الحقول والأزرار في تصاميم Stitch = 52px.
  static const double buttonHeight = 52.0;
  static const double inputHeight = 52.0;
}
