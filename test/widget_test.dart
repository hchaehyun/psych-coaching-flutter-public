import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:psych_coaching_flutter/core/router/app_router.dart';
import 'package:psych_coaching_flutter/main.dart';

void main() {
  testWidgets('MyApp renders with overridden router', (
    WidgetTester tester,
  ) async {
    final testRouter = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            return const Scaffold(body: Center(child: Text('Test Route')));
          },
        ),
      ],
    );
    addTearDown(testRouter.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRouterProvider.overrideWith((ref) => testRouter)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Route'), findsOneWidget);
  });
}
