import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Escala tipográfica: Quicksand para títulos y botones, Nunito para lectura.
/// Los tamaños están en `sp` lógicos, así respetan la escala de fuente del
/// sistema.
abstract final class AppFonts {
  static const display = 'Quicksand';
  static const body = 'Nunito';
}

abstract final class AppTheme {
  static const _radius = 20.0;

  static TextTheme _textTheme() {
    const q = AppFonts.display;
    const n = AppFonts.body;
    return TextTheme(
      displaySmall: TextStyle(
        fontFamily: q,
        fontSize: 34,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: AppColors.ink,
      ),
      headlineMedium: TextStyle(
        fontFamily: q,
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: AppColors.ink,
      ),
      headlineSmall: TextStyle(
        fontFamily: q,
        fontSize: 23,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.ink,
      ),
      titleLarge: TextStyle(
        fontFamily: q,
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      titleMedium: TextStyle(
        fontFamily: q,
        fontSize: 17,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      titleSmall: TextStyle(
        fontFamily: q,
        fontSize: 15,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      bodyLarge: TextStyle(
        fontFamily: n,
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
      ),
      bodyMedium: TextStyle(
        fontFamily: n,
        fontSize: 14.5,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: AppColors.inkSoft,
      ),
      bodySmall: TextStyle(
        fontFamily: n,
        fontSize: 12.5,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: AppColors.inkSoft,
      ),
      labelLarge: TextStyle(
        fontFamily: q,
        fontSize: 16,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontFamily: n,
        fontSize: 12.5,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: AppColors.inkSoft,
      ),
      labelSmall: TextStyle(
        fontFamily: n,
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.7,
        color: AppColors.teal,
      ),
    );
  }

  /// Tema claro (usado también en pruebas).
  static ThemeData light() {
    AppColors.dark = false;
    return build();
  }

  /// Tema con la paleta activa de [AppColors] (clara u oscura).
  static ThemeData build() {
    final dark = AppColors.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          brightness: dark ? Brightness.dark : Brightness.light,
        ).copyWith(
          primary: AppColors.teal,
          onPrimary: Colors.white,
          primaryContainer: AppColors.cyanSoft,
          onPrimaryContainer: AppColors.tealDark,
          secondary: AppColors.green,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.mintSoft,
          onSecondaryContainer: AppColors.greenDeep,
          tertiary: AppColors.blue,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
          onSurfaceVariant: AppColors.inkSoft,
          surfaceContainerLowest: AppColors.surface,
          surfaceContainerLow: AppColors.background,
          surfaceContainer: AppColors.surfaceTint,
          surfaceContainerHigh: AppColors.surfaceBlue,
          outline: AppColors.outline,
          outlineVariant: AppColors.outline,
          error: AppColors.red,
        );
    final text = _textTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppFonts.body,
      textTheme: text,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        foregroundColor: AppColors.ink,
        systemOverlayStyle:
            (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                .copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: Colors.transparent,
                ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.blueSoft,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.blue
                : AppColors.inkSoft,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.blue
                : AppColors.inkSoft,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(_radius)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: text.bodyLarge?.copyWith(color: AppColors.inkMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: AppColors.outline, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: AppColors.outline, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: AppColors.teal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: AppColors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: AppColors.red, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFF2A4058) : AppColors.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.outline,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue,
          textStyle: text.labelLarge,
          minimumSize: const Size(48, 48),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.cyan,
        linearTrackColor: AppColors.blueSoft,
      ),
      dividerTheme: DividerThemeData(color: AppColors.outline),
    );
  }
}
