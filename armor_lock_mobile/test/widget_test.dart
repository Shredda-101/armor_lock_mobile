import 'package:armor_lock_mobile/app/armor_lock_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the locked vault entry screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ArmorLockApp());

    expect(find.text('Armor Lock'), findsOneWidget);
    expect(find.text('Unlock Vault'), findsOneWidget);
    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
  });
}
