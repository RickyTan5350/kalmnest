import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_codelab/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('Localization test for English and Malay', (
    WidgetTester tester,
  ) async {
    // Test English
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) {
            return Text(AppLocalizations.of(context)!.helloWorld);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hello World'), findsOneWidget);

    // Test Malay
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ms'),
        home: Builder(
          builder: (context) {
            return Text(AppLocalizations.of(context)!.helloWorld);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Halo Dunia'), findsOneWidget);
  });
}
