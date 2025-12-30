import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_play/admin_teacher/widgets/user/profile_header_content.dart';
import 'package:code_play/controllers/locale_controller.dart';
import 'package:code_play/l10n/generated/app_localizations.dart';
import 'package:code_play/models/user_data.dart';

void main() {
  testWidgets('Language switcher changes locale', (WidgetTester tester) async {
    // Mock user
    final user = UserDetails(
      id: '1',
      name: 'Test User',
      email: 'test@example.com',
      phoneNo: '1234567890',
      address: 'Test Address',
      gender: 'Male',
      accountStatus: 'active',
      roleName: 'admin',
      joinedDate: '2023-01-01',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProfileHeaderContent(
            currentUser: user,
            onLogoutPressed: () {},
            onMenuPressed: () {},
          ),
        ),
      ),
    );

    // Initial state (assuming default is EN)
    expect(LocaleController.instance.value, const Locale('en'));
    expect(find.text('EN'), findsOneWidget);

    // Open language menu
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();

    // Select Malay
    await tester.tap(find.text('Bahasa Malaysia'));
    await tester.pumpAndSettle();

    // Verify controller updated
    expect(LocaleController.instance.value, const Locale('ms'));
    expect(find.text('MS'), findsOneWidget);
  });
}
