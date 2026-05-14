/// Neumorphic Style Utilities
///
/// Provides consistent neumorphic styling throughout the app to match the soft UI design
/// of the app icon. Includes shadow configurations, border radius, and color schemes.
// ignore_for_file: deprecated_member_use
library;

import 'package:flutter/material.dart';

/// Utility class for neumorphic styling that matches the app icon's soft UI design
class NeumorphicStyle {
  // Color palette matching the dashboard gradient
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color secondaryBlue = Color(0xFF4FC3F7);
  static const Color lightBlue = Color(0xFFE8F4FD);
  static const Color veryLightBlue = Color(0xFFF0F8FF);
  static const Color backgroundBlue = Color(0xFFFAFCFF);
  static const Color surfaceBlue = Color(0xFFF5F9FF);
  static const Color darkText = Color(0xFF2C3E50);
  static const Color lightText = Color(0xFF7F8C8D);
  static const Color softBorder = Color(0xFFE1EFF9);
  static const Color mediumBorder = Color(0xFFB8D4F0);
  static const Color golden = Color(0xFFFFD700);

  /// Creates a neumorphic container with soft shadows
  static BoxDecoration neumorphicContainer({
    Color? color,
    double borderRadius = 20,
    bool isPressed = false,
    bool isElevated = true,
  }) {
    return BoxDecoration(
      color: color ?? backgroundBlue,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: isElevated ? [
        // Outer shadow (bottom-right)
        BoxShadow(
          color: const Color(0xFFD1E7F0).withOpacity(0.3),
          offset: const Offset(4, 4),
          blurRadius: 8,
          spreadRadius: 0,
        ),
        // Inner shadow (top-left) for pressed state
        if (isPressed)
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            offset: const Offset(-2, -2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        // Soft inner shadow for depth
        BoxShadow(
          color: Colors.white.withOpacity(0.9),
          offset: const Offset(-1, -1),
          blurRadius: 2,
          spreadRadius: 0,
        ),
      ] : null,
      border: Border.all(
        color: softBorder,
        width: 1,
      ),
    );
  }

  /// Creates a neumorphic button style
  static ButtonStyle neumorphicButton({
    Color? backgroundColor,
    Color? foregroundColor,
    double borderRadius = 16,
    bool isPressed = false,
  }) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.all(
        backgroundColor ?? backgroundBlue,
      ),
      foregroundColor: WidgetStateProperty.all(
        foregroundColor ?? primaryBlue,
      ),
      elevation: WidgetStateProperty.all(0),
      shadowColor: WidgetStateProperty.all(Colors.transparent),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  /// Creates a neumorphic card decoration
  static BoxDecoration neumorphicCard({
    Color? color,
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      color: color ?? backgroundBlue,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFD1E7F0).withOpacity(0.2),
          offset: const Offset(2, 2),
          blurRadius: 6,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.9),
          offset: const Offset(-1, -1),
          blurRadius: 2,
          spreadRadius: 0,
        ),
      ],
      border: Border.all(
        color: softBorder,
        width: 1,
      ),
    );
  }

  /// Creates a neumorphic input field decoration
  static InputDecoration neumorphicInput({
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: surfaceBlue,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: softBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: softBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: const TextStyle(color: lightText),
      labelStyle: const TextStyle(color: darkText),
    );
  }

  /// Creates a neumorphic progress indicator style
  static LinearProgressIndicator neumorphicProgress({
    required double value,
    Color? backgroundColor,
    Color? valueColor,
    double height = 8,
  }) {
    return LinearProgressIndicator(
      value: value,
      backgroundColor: backgroundColor ?? surfaceBlue,
      valueColor: AlwaysStoppedAnimation<Color>(
        valueColor ?? primaryBlue,
      ),
      minHeight: height,
    );
  }

  /// Creates a neumorphic circular progress indicator
  static Widget neumorphicCircularProgress({
    required double value,
    double size = 120,
    double strokeWidth = 8,
    Color? backgroundColor,
    Color? valueColor,
    Widget? child,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: neumorphicContainer(
        borderRadius: size / 2,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: strokeWidth,
            backgroundColor: backgroundColor ?? surfaceBlue,
            valueColor: AlwaysStoppedAnimation<Color>(
              valueColor ?? primaryBlue,
            ),
          ),
          if (child != null) child,
        ],
      ),
    );
  }

  /// Creates a neumorphic icon button
  static Widget neumorphicIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? iconColor,
    double size = 48,
    double borderRadius = 12,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: neumorphicContainer(
          borderRadius: borderRadius,
        ),
        child: Icon(
          icon,
          color: iconColor ?? primaryBlue,
          size: size * 0.4,
        ),
      ),
    );
  }

  /// Creates a neumorphic text style
  static TextStyle neumorphicText({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? darkText,
    );
  }

  /// Creates a neumorphic gradient background
  static BoxDecoration neumorphicGradient({
    List<Color>? colors,
    Alignment? begin,
    Alignment? end,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors ?? [
          backgroundBlue,
          veryLightBlue,
          backgroundBlue,
        ],
        begin: begin ?? Alignment.topLeft,
        end: end ?? Alignment.bottomRight,
      ),
    );
  }

  /// Creates the primary blue gradient used throughout the app (matches Figma)
  /// Gradient from #4FC3F7 to #2196F3 at 135 degrees
  static LinearGradient primaryGradient({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      colors: [secondaryBlue, primaryBlue],
      begin: begin,
      end: end,
    );
  }

  /// Creates the splash screen gradient background (matches Figma)
  static LinearGradient splashGradient() {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white,
        const Color(0xFFE3F2FD),
        const Color(0xFFBBDEFB),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  /// Creates a primary button style with gradient (matches Figma)
  static BoxDecoration primaryButtonDecoration({
    bool enabled = true,
  }) {
    return BoxDecoration(
      gradient: enabled ? primaryGradient() : null,
      color: enabled ? null : lightText.withOpacity(0.3),
      borderRadius: BorderRadius.circular(16),
      boxShadow: enabled
          ? [
              BoxShadow(
                color: primaryBlue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  /// Creates a dialog shadow (matches Figma)
  static List<BoxShadow> dialogShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ];
  }

  /// Creates a bottom nav shadow (matches Figma)
  static List<BoxShadow> bottomNavShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, -5),
      ),
    ];
  }

  /// Creates a card shadow (matches Figma)
  static List<BoxShadow> cardShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Creates a progress circle shadow (matches Figma)
  static List<BoxShadow> progressCircleShadow() {
    return [
      BoxShadow(
        color: primaryBlue.withOpacity(0.15),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }

  /// Creates a center FAB shadow (matches Figma)
  static List<BoxShadow> centerFabShadow() {
    return [
      BoxShadow(
        color: primaryBlue.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  /// Standard border radius values (matches Figma)
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 24.0;
  static const double radiusXXLarge = 28.0;
  static const double radiusXXXLarge = 30.0;

  /// Standard spacing values (matches Figma)
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 12.0;
  static const double spacingLG = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;
}
