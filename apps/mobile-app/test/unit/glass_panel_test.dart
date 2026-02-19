import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';

void main() {
  testWidgets('GlassPanel renders child and responds to tap', (WidgetTester tester) async {
    bool tapped = false;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GestureDetector(
            onTap: () => tapped = true,
            child: const GlassPanel(
              child: Text('Hello Glass'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Hello Glass'), findsOneWidget);
    
    await tester.tap(find.text('Hello Glass'));
    await tester.pump();
    
    expect(tapped, isTrue);
  });
}
