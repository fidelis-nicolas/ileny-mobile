import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_shape.dart';
import 'app_typography.dart';

/// The app's two themes, both built from the same [AppPalette] so a token
/// changes in one place and lands everywhere.
///
/// The goal here is that ordinary screens need no colors of their own: a
/// `Text` with no style, a `Card`, a `TextField`, an `AppBar` should already
/// look right in both brightnesses. Every `color:` a screen sets by hand is a
/// place the theme has to be kept in step manually, so prefer the semantic
/// slots (`titleLarge`, `bodySmall`, …) over inline `TextStyle`s.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppPalette.light);

  static ThemeData get dark => _build(AppPalette.dark);

  static ThemeData _build(AppPalette palette) {
    final isDark = palette.brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: palette.brightness,
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      primaryContainer: palette.primarySoft,
      onPrimaryContainer: palette.primary,
      secondary: palette.accent,
      onSecondary: Colors.white,
      secondaryContainer: isDark ? const Color(0xFF2E1E16) : const Color(0xFFF6E9E1),
      onSecondaryContainer: palette.accentInk,
      error: palette.danger,
      onError: Colors.white,
      surface: palette.surface,
      onSurface: palette.textBody,
      surfaceContainerLowest: palette.background,
      surfaceContainerLow: palette.background,
      surfaceContainer: palette.surface,
      surfaceContainerHigh: palette.surfaceAlt,
      surfaceContainerHighest: palette.surfaceAlt,
      onSurfaceVariant: palette.textMuted,
      outline: palette.border,
      outlineVariant: palette.border,
      shadow: palette.shadowTint,
      scrim: palette.shadowTint,
      inverseSurface: isDark ? palette.textHeading : const Color(0xFF262220),
      onInverseSurface: isDark ? palette.background : const Color(0xFFF7F4EF),
      inversePrimary: isDark ? AppColors.primary600 : AppColors.primary300,
    );

    final textTheme = AppTypography.textTheme(
      heading: palette.textHeading,
      body: palette.textBody,
      muted: palette.textMuted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      textTheme: textTheme,
      // Registered here so `context.palette` works anywhere under the app.
      extensions: [palette],

      iconTheme: IconThemeData(color: palette.textBody, size: 22),
      primaryIconTheme: IconThemeData(color: palette.primary),

      // Flat, paper-colored, no M3 surface tint and no shadow when content
      // scrolls under it — the tint is the single most recognisable "stock
      // Material" tell.
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textHeading,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: palette.textBody, size: 22),
        actionsIconTheme: IconThemeData(color: palette.textBody, size: 22),
      ),

      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: palette.shadowTint,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: palette.border),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.inputFill,
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(color: palette.primary),
        prefixIconColor: palette.textMuted,
        suffixIconColor: palette.textMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: palette.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: palette.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: palette.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: palette.danger, width: 1.5),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: palette.danger),
      ),

      // Primary actions carry the brand green, as they do on the web. The
      // terracotta stays an accent — for highlights, badges, and rules — rather
      // than the app's main button colour.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          disabledBackgroundColor: palette.surfaceAlt,
          disabledForegroundColor: palette.textMuted,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: textTheme.labelLarge,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          backgroundColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: palette.border),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: palette.primary,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
      ),

      // M3's NavigationBar, not the Material 2 BottomNavigationBar — the pill
      // indicator and the taller touch target are half of why current apps
      // read as current.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        indicatorColor: palette.primarySoft,
        indicatorShape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? palette.primary
                : palette.textMuted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? palette.primary : palette.textMuted,
          );
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceAlt,
        selectedColor: palette.primary,
        disabledColor: palette.surfaceAlt,
        side: BorderSide(color: palette.border),
        labelStyle: textTheme.labelMedium?.copyWith(color: palette.textBody),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: palette.onPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        showCheckmark: false,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: palette.textMuted,
        textColor: palette.textBody,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: palette.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: isDark ? AppColors.primary600 : AppColors.primary200,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        elevation: 0,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
        linearTrackColor: palette.surfaceAlt,
        circularTrackColor: Colors.transparent,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.onPrimary;
          return palette.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.primary;
          return palette.surfaceAlt;
        }),
        trackOutlineColor: WidgetStateProperty.all(palette.border),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(palette.onPrimary),
        side: BorderSide(color: palette.inputBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.primary;
          return palette.inputBorder;
        }),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: palette.primary,
        unselectedLabelColor: palette.textMuted,
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: palette.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: palette.border,
      ),

      badgeTheme: BadgeThemeData(
        backgroundColor: palette.accent,
        textColor: Colors.white,
        textStyle: textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),

      splashFactory: InkSparkle.splashFactory,

      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
