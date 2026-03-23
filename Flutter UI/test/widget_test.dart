import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ✅ Fixed: correct package name (Gym) and class (GymCoachingApp)
import 'package:Gym/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GymCoachingApp(),
      ),
    );
    // App should render without throwing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
