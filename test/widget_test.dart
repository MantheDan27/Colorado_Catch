// Basic smoke tests that don't require Firebase to be initialized.
//
// Widgets that talk to Firebase (AuthService, FirestoreService, etc.) need
// platform channel mocks to test in isolation; add package:firebase_auth_mocks
// or similar if you want to cover those paths.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colorado_catch/widgets/loading_indicator.dart';

void main() {
  testWidgets('LoadingIndicator shows a progress spinner', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoadingIndicator()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
