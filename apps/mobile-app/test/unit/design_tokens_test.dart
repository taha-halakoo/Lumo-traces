import 'package:flutter_test/flutter_test.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

void main() {
  group('DesignTokens Tests', () {
    test('Colors are correctly defined', () {
      expect(DesignTokens.glassDarkBase, const Color(0xFF0A0E17));
      expect(DesignTokens.liquidBlue, const Color(0xFF4A90E2));
    });

    test('Blur values are within expected range', () {
      expect(DesignTokens.blurMedium, 20.0);
      expect(DesignTokens.blurHigh, 40.0);
    });
  });
}
