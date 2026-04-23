import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:voice_phishing/main.dart';
import 'package:voice_phishing/providers/app_provider.dart';

void main() {
  testWidgets('Safe-Call app completes onboarding flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const SafeCallApp(),
      ),
    );

    expect(find.text('Safe-Call AI'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Live Translation'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Phishing Shield'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Select Your Language'), findsOneWidget);

    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Protection'));
    await tester.pumpAndSettle();

    expect(find.text('Protection Active'), findsOneWidget);
  });
}
