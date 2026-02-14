import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:traces_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App starts, checks auth, and loads map', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Verify Splash Screen appears
    expect(find.text('TRACES'), findsOneWidget);
    
    // Wait for Splash delay (3s)
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Check if we are on Login or Map
    if (find.text('AUTHENTICATION').evaluate().isNotEmpty) {
      print("On Login Screen");
      // TODO: Perform Login
    } else {
      print("On Map Screen");
      expect(find.byIcon(Icons.search), findsOneWidget); // Search bar
      expect(find.byIcon(Icons.radar), findsOneWidget); // Scanning chip
    }
  });
}
