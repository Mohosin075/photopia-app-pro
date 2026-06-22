import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:photopya/core/localization/app_localizations.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('Test localization translation loading', (WidgetTester tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('fr')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: [
                  ...context.localizationDelegates,
                  AppLocalizations.delegate,
                ],
                home: Scaffold(
                  body: Builder(
                    builder: (childContext) {
                      final l = AppLocalizations.of(childContext);
                      return Column(
                        children: [
                          Text(l?.settings ?? 'null'),
                          Text(l?.language ?? 'null'),
                          Text(l?.signUpBtn ?? 'null'),
                          Text(l?.detectingLocation ?? 'null'),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify initial values in English
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Detecting location...'), findsOneWidget);

    // Switch locale to French
    final BuildContext context = tester.element(find.byType(MaterialApp).first);
    context.setLocale(const Locale('fr'));

    await tester.pumpAndSettle();

    // Verify French translations
    expect(find.text('Paramètres'), findsOneWidget);
    expect(find.text('Langue'), findsOneWidget);
    expect(find.text('S\'inscrire'), findsOneWidget);
    expect(find.text('Détection de l\'emplacement...'), findsOneWidget);
  });
}
