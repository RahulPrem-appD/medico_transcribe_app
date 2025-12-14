import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico_transcribe/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MedicoTranscribeApp());

    // Verify that the app launches with the home screen
    expect(find.text('Dr. Sharma'), findsOneWidget);
    expect(find.text('New Consultation'), findsOneWidget);
    expect(find.text('Browse Reports'), findsOneWidget);
  });
}
