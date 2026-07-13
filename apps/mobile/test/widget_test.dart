// Smoke test for the MediVerify brand mark. (Replaces the stale default
// counter test that referenced a package name this app never used.)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mediverify/widgets/brand.dart';

void main() {
  testWidgets('MediLogo renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: MediLogo(size: 96)),
        ),
      ),
    );

    expect(find.byType(MediLogo), findsOneWidget);
  });
}
