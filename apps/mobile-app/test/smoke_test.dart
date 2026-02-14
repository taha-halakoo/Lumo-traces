import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traces_mobile/main.dart';

void main() {
  testWidgets('Smoke test - App builds', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: TracesApp()));

    // Verify that we are on the Login Screen (or at least no crash)
    // LoginScreen has "TRACES" text.
    expect(find.text('TRACES'), findsOneWidget);
  });
}
