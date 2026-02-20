import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sada/features/duress/presentation/pages/safe_notes_screen.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock Clipboard
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            return null;
          }
          return null;
        });
  });

  Widget createWidgetUnderTest() {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => const MaterialApp(home: SafeNotesScreen()),
    );
  }

  testWidgets('SafeNotesScreen renders list of notes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify AppBar
    expect(find.text('My Notes'), findsOneWidget);

    // Verify categories
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Recipes'), findsOneWidget);
    expect(find.text('Ideas'), findsOneWidget);

    // Verify content snippet
    expect(find.textContaining('Meeting Notes'), findsOneWidget);
    expect(find.textContaining('Grocery List'), findsOneWidget);
  });

  testWidgets('Copy button shows validation snackbar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Find first copy button
    final copyButton = find.byIcon(Icons.copy).first;
    expect(copyButton, findsOneWidget);

    // Tap it
    await tester.tap(copyButton);
    await tester.pump(); // Start animation
    await tester.pumpAndSettle(); // Wait for snackbar animation

    // Verify SnackBar appears
    expect(find.text('Copied to clipboard'), findsOneWidget);
  });
}
