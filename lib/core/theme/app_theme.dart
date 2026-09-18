import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Brand Palette ─────────────────────────────────────────────────────────
  // Primary: Emerald
  static const Color primary = Color(0xFF059669); // Emerald-600
  static const Color primaryLight = Color(0xFF34D399); // Emerald-400
  static const Color primaryDark = Color(0xFF047857); // Emerald-700
  static const Color primaryDeep = Color(0xFF064E3B); // Emerald-900

  // Secondary: Indigo
  static const Color secondary = Color(0xFF6366F1); // Indigo-500
  static const Color secondaryLight = Color(0xFF818CF8); // Indigo-400
  static const Color secondaryDark = Color(0xFF4F46E5); // Indigo-600

  // Accent: Amber
  static const Color accent = Color(0xFFF59E0B); // Amber-500
  static const Color accentLight = Color(0xFFFBBF24); // Amber-400

  // Neutral
  static const Color textPrimary = Color(0xFF111827); // Gray-900
  static const Color textSecondary = Color(0xFF6B7280); // Gray-500
  static const Color textTertiary = Color(0xFF9CA3AF); // Gray-400

  // ── Surface Tokens ────────────────────────────────────────────────────────
  // Light
  static const Color surfaceLight = Color(0xFFF9FAFB); // Gray-50
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5E7EB); // Gray-200

  // Dark
  static const Color surfaceDark = Color(0xFF030712); // Gray-950
  static const Color cardDark = Color(0xFF111827); // Gray-900
  static const Color cardDark2 = Color(0xFF1F2937); // Gray-800
  static const Color borderDark = Color(0xFF374151); // Gray-700

  // Semantic
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF3B82F6);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF0D9488)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF047857), Color(0xFF059669), Color(0xFF0891B2)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
  );

  // ── Per-Tool Category Gradients ───────────────────────────────────────────
  // Each tool gets a unique, rich gradient
  static const toolGradients = [
    // Scan
    LinearGradient(
      colors: [Color(0xFF059669), Color(0xFF0D9488)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Image to PDF
    LinearGradient(
      colors: [Color(0xFF1D4ED8), Color(0xFF6366F1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Merge PDF
    LinearGradient(
      colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Compress
    LinearGradient(
      colors: [Color(0xFFEA580C), Color(0xFFF59E0B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Split
    LinearGradient(
      colors: [Color(0xFFB91C1C), Color(0xFFDB2777)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Sign
    LinearGradient(
      colors: [Color(0xFF0E7490), Color(0xFF0891B2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // OCR
    LinearGradient(
      colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Text to PDF
    LinearGradient(
      colors: [Color(0xFF047857), Color(0xFF059669)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Watermark
    LinearGradient(
      colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Encrypt
    LinearGradient(
      colors: [Color(0xFF374151), Color(0xFF4B5563)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // PDF to Image
    LinearGradient(
      colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // ID Photo
    LinearGradient(
      colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Organize Pages
    LinearGradient(
      colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Unlock PDF
    LinearGradient(
      colors: [Color(0xFFCA8A04), Color(0xFFEAB308)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  // ── Typography ────────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.plusJakartaSansTextTheme(base).copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 57,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 45,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(
      ThemeData.light().textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFD1FAE5),
        onPrimaryContainer: primaryDeep,
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFE0E7FF),
        onSecondaryContainer: const Color(0xFF312E81),
        tertiary: accent,
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFFFEF3C7),
        onTertiaryContainer: const Color(0xFF78350F),
        error: error,
        onError: Colors.white,
        errorContainer: const Color(0xFFFEE2E2),
        onErrorContainer: const Color(0xFF7F1D1D),
        surface: surfaceLight,
        onSurface: textPrimary,
        surfaceContainerHighest: borderLight,
        onSurfaceVariant: textSecondary,
        outline: borderLight,
        outlineVariant: const Color(0xFFF3F4F6),
        shadow: const Color(0x1A000000),
        scrim: const Color(0x4D000000),
        inverseSurface: const Color(0xFF1F2937),
        onInverseSurface: Colors.white,
        inversePrimary: primaryLight,
        surfaceTint: primary,
      ),
      scaffoldBackgroundColor: surfaceLight,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: surfaceLight,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: StadiumBorder(),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardLight,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: primary,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: Color(0xFF9CA3AF), size: 24);
        }),
        height: 72,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF3F4F6),
        selectedColor: primary.withValues(alpha: 0.12),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: textTertiary,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: textSecondary,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? primary
              : const Color(0xFFD1D5DB),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
        inactiveTrackColor: borderLight,
        trackHeight: 4,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1F2937),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),

      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cardLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 24,
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(
      ThemeData.dark().textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: primaryLight,
        onPrimary: primaryDeep,
        primaryContainer: primaryDark,
        onPrimaryContainer: const Color(0xFFA7F3D0),
        secondary: secondaryLight,
        onSecondary: const Color(0xFF1E1B4B),
        secondaryContainer: secondaryDark,
        onSecondaryContainer: const Color(0xFFC7D2FE),
        tertiary: accentLight,
        onTertiary: const Color(0xFF451A03),
        tertiaryContainer: const Color(0xFF78350F),
        onTertiaryContainer: const Color(0xFFFDE68A),
        error: const Color(0xFFFCA5A5),
        onError: const Color(0xFF7F1D1D),
        errorContainer: const Color(0xFF991B1B),
        onErrorContainer: const Color(0xFFFECACA),
        surface: surfaceDark,
        onSurface: const Color(0xFFF9FAFB),
        surfaceContainerHighest: borderDark,
        onSurfaceVariant: const Color(0xFF9CA3AF),
        outline: borderDark,
        outlineVariant: const Color(0xFF1F2937),
        shadow: Colors.black,
        scrim: Colors.black54,
        inverseSurface: const Color(0xFFF9FAFB),
        onInverseSurface: textPrimary,
        inversePrimary: primaryDark,
        surfaceTint: primaryLight,
      ),
      scaffoldBackgroundColor: surfaceDark,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: primaryDeep,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: primaryDeep,
        elevation: 4,
        shape: StadiumBorder(),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardDark,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryLight.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: primaryLight,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryLight, size: 24);
          }
          return const IconThemeData(color: Color(0xFF6B7280), size: 24);
        }),
        height: 72,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1F2937),
        selectedColor: primaryLight.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: const Color(0xFF6B7280),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: const Color(0xFF9CA3AF),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primaryDeep : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? primaryLight
              : const Color(0xFF374151),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: primaryLight,
        thumbColor: primaryLight,
        overlayColor: primaryLight.withValues(alpha: 0.15),
        inactiveTrackColor: borderDark,
        trackHeight: 4,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF374151),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),

      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        textColor: Colors.white,
        iconColor: const Color(0xFF9CA3AF),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 24,
      ),
    );
  }

  // ── Glass Effect Helper ───────────────────────────────────────────────────
  static BoxDecoration glassDecoration({bool isDark = true}) => BoxDecoration(
    color: isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.7),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.white.withValues(alpha: 0.9),
    ),
  );

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> cardShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: color.withValues(alpha: 0.1),
      blurRadius: 6,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // Legacy & dynamic resolution helpers
  static const Color primaryGreen = primary;
  static const Color surface = surfaceLight;

  static Color surfaceColor(bool isDark) => isDark ? surfaceDark : surfaceLight;
  static Color cardColor(bool isDark) => isDark ? cardDark : cardLight;
  static Color cardColor2(bool isDark) => isDark ? cardDark2 : cardLight;
  static Color borderColor(bool isDark) => isDark ? borderDark : borderLight;
  static Color textColor(bool isDark) => isDark ? Colors.white : textPrimary;
  static Color textSecondaryColor(bool isDark) =>
      isDark ? const Color(0xFF9CA3AF) : textSecondary;

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cardDark, surfaceDark],
  );
}
