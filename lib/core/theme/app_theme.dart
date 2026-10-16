import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

/// الثيم الموحّد — مبني مباشرة على رموز `_design/DESIGN.md`.
///
/// نظام الألوان في التصميم هو نظام Material 3 كاملاً، لذلك يُبنى
/// [ColorScheme] برموزه الحقيقية بدل تقريبها.
class AppTheme {
  AppTheme._();

  static const ColorScheme _scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    primaryFixed: AppColors.primaryFixed,
    primaryFixedDim: AppColors.primaryFixedDim,
    onPrimaryFixed: AppColors.onPrimaryFixed,
    onPrimaryFixedVariant: AppColors.onPrimaryFixedVariant,
    inversePrimary: AppColors.inversePrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    secondaryFixed: AppColors.secondaryFixed,
    secondaryFixedDim: AppColors.secondaryFixedDim,
    onSecondaryFixed: AppColors.onSecondaryFixed,
    onSecondaryFixedVariant: AppColors.onSecondaryFixedVariant,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    tertiaryFixed: AppColors.tertiaryFixed,
    tertiaryFixedDim: AppColors.tertiaryFixedDim,
    onTertiaryFixed: AppColors.onTertiaryFixed,
    onTertiaryFixedVariant: AppColors.onTertiaryFixedVariant,
    error: AppColors.errorColor,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surfaceColor,
    onSurface: AppColors.onSurface,
    surfaceDim: AppColors.surfaceDim,
    surfaceBright: AppColors.surfaceBright,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    inverseSurface: AppColors.inverseSurface,
    onInverseSurface: AppColors.onInverseSurface,
    surfaceTint: AppColors.surfaceTint,
  );

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: _scheme,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryContainer,

      // شريط علوي شفاف على خلفية الشاشة.
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headlineMd,
      ),

      // حقول الإدخال: تعبئة رمادية فاتحة، نصف قطر 8px، حدّ رفيع،
      // وتركيز بلون أخضر — كما في DESIGN.md.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.stackMd,
          vertical: AppDimensions.stackMd,
        ),
        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.outline),
        labelStyle: AppTextStyles.bodyMd,
        border: _inputBorder(AppColors.outlineVariant),
        enabledBorder: _inputBorder(AppColors.outlineVariant),
        focusedBorder: _inputBorder(AppColors.primaryContainer, width: 1.6),
        errorBorder: _inputBorder(AppColors.errorColor),
        focusedErrorBorder: _inputBorder(AppColors.errorColor, width: 1.6),
      ),

      // الزر الأساسي: أخضر بشكل حبّة كاملة ونص عريض أبيض.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.white,
          disabledBackgroundColor:
              AppColors.primaryContainer.withValues(alpha: 0.45),
          disabledForegroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          elevation: 0,
          textStyle: AppTextStyles.labelBold,
          shape: const StadiumBorder(),
        ),
      ),

      // الزر الثانوي (ghost): حدّ رفيع بلا تعبئة، بنفس شكل الحبّة.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          side: const BorderSide(color: AppColors.outlineVariant),
          textStyle: AppTextStyles.labelBold,
          shape: const StadiumBorder(),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelBold,
        ),
      ),

      // البطاقات: بيضاء، نصف قطر 16px، بلا ظل افتراضي
      // (الظل يُضاف يدوياً عبر AppDimensions.cardShadow لمطابقة التصميم).
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceContainerLow,
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: AppTextStyles.bodySm.copyWith(color: AppColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
        ),
      ),

      // apply(fontFamily:) يضمن أن حتى الأنماط غير المذكورة هنا
      // (التي ترثها ودجتات Material الداخلية) تستخدم Readex Pro.
      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.headlineXl,
        headlineMedium: AppTextStyles.headlineLg,
        headlineSmall: AppTextStyles.headlineMd,
        titleLarge: AppTextStyles.headlineLgMobile,
        titleMedium: AppTextStyles.headlineMd,
        bodyLarge: AppTextStyles.bodyLg,
        bodyMedium: AppTextStyles.bodyMd,
        bodySmall: AppTextStyles.bodySm,
        labelLarge: AppTextStyles.labelBold,
        labelSmall: AppTextStyles.labelSm,
      ).apply(fontFamily: AppTextStyles.fontFamily),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
