import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xpense_traker/app.dart';

void main() {
  testWidgets('App boots and shows onboarding on fresh install',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: XpenseApp()));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(find.text('Welcome to Xpense Tracker'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
