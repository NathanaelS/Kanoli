import 'package:flutter_test/flutter_test.dart';
import 'package:kanoli_flutter/app/app.dart';
import 'package:kanoli_flutter/core/config/app_environment.dart';
import 'package:kanoli_flutter/core/logging/app_logger.dart';

void main() {
  testWidgets('renders startup board shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      KanoliApp(
        environment: AppEnvironment.dev,
        logger: AppLogger(environment: AppEnvironment.dev),
        previousStartupIncomplete: false,
        startupStateKey: 'test.startup.key',
      ),
    );

    expect(find.text('Kanoli'), findsOneWidget);
    expect(find.textContaining('No board open'), findsOneWidget);
    expect(find.text('Create File'), findsOneWidget);
    expect(find.text('Open File'), findsOneWidget);
  });
}
