import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/services/onboarding_service.dart';
import 'package:saefra_run/features/onboarding/screens/activity_level_screen.dart';

void main() {
  setUpAll(() async {
    dotenv.testLoad(fileInput: 'BASE_URL=https://api.saefra.run\nUSE_MOCK_API=true\nENVIRONMENT=development');
  });

  testWidgets('ActivityLevelScreen renders without crashing', (WidgetTester tester) async {
    final onboardingService = OnboardingService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<OnboardingService>.value(value: onboardingService),
        ],
        child: const MaterialApp(
          home: ActivityLevelScreen(),
        ),
      ),
    );

    expect(find.byType(ActivityLevelScreen), findsOneWidget);
  });
}
