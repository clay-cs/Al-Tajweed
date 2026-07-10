import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_ai/app.dart';
import 'package:quran_ai/core/storage/app_prefs.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppPrefs.init();

    await tester.pumpWidget(const QuranAiApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Quran AI'), findsOneWidget);

    // Let the splash navigation timer finish so the test ends cleanly.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
