import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: DesignTokens.glassDarkBase,
      primaryColor: DesignTokens.liquidBlue,
      colorScheme: const ColorScheme.dark(
        primary: DesignTokens.liquidBlue,
        secondary: DesignTokens.electricPurple,
        surface: Colors.transparent, // Important for glass layers
        error: DesignTokens.signalRed,
        onSurface: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
        bodyMedium: GoogleFonts.roboto(fontSize: 14, color: Colors.white60), 
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.liquidBlue.withValues(alpha: 0.8),
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      cardTheme: CardThemeData(
        color: DesignTokens.glassLightBase.withValues(alpha: DesignTokens.opacityGlassLow),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(DesignTokens.radiusMedium)),
          side: BorderSide(color: Colors.white.withValues(alpha: DesignTokens.opacityBorder), width: 1),
        ),
      ),
    );
  }
}
