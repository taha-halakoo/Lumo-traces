import 'package:flutter/material.dart';

/// Design Tokens for the "Liquid Glass" System
/// Based on mapui.png analysis and iOS Glassmorphism principles.
class DesignTokens {
  // --- Colors ---
  static const Color glassDarkBase = Color(0xFF0A0E17); // Deep Ocean
  static const Color glassLightBase = Color(0xFFFFFFFF);
  
  // Accents
  static const Color liquidBlue = Color(0xFF4A90E2);
  static const Color electricPurple = Color(0xFF9D50BB);
  static const Color signalRed = Color(0xFFFF4B4B); // For Proximity Bar
  static const Color neonGreen = Color(0xFF00E676);

  // --- Opacity Levels ---
  static const double opacityGlassLow = 0.12;  // Standard Panels
  static const double opacityGlassMedium = 0.25; // Active States
  static const double opacityGlassHigh = 0.60;   // Heavy overlays
  static const double opacityBorder = 0.15;      // "Catching the light"

  // --- Blur Sigmas ---
  static const double blurLow = 10.0;
  static const double blurMedium = 20.0; // Standard iOS Glass
  static const double blurHigh = 40.0;   // Background layers

  // --- Radii ---
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 24.0; // Cards
  static const double radiusLarge = 32.0;  // Pills / Capsules
  static const double radiusFull = 100.0;  // Circles

  // --- Gradients ---
  static const LinearGradient liquidGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x20FFFFFF), // Top-left shine
      Color(0x05FFFFFF), // Bottom-right fade
    ],
  );
  
  static const LinearGradient proximityGradient = LinearGradient(
    colors: [Colors.transparent, signalRed],
    stops: [0.0, 1.0],
  );

  // --- Shadows ---
  static const List<BoxShadow> shadowFloating = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 20,
      offset: Offset(0, 10),
      spreadRadius: -5,
    ),
  ];
}
