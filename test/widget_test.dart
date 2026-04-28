import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:careerkit_mobile_dashboard/main.dart';

void main() {
  testWidgets('checks a ready CV', (WidgetTester tester) async {
    await tester.pumpWidget(const CareerKitApp());

    expect(find.text('CareerKit Mobile Dashboard'), findsOneWidget);
    expect(find.text('Target Role'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('skillsField')), '3');
    await tester.enterText(find.byKey(const ValueKey('projectsField')), '1');

    const checkboxKeys = [
      ValueKey('contactCheckbox'),
      ValueKey('educationCheckbox'),
      ValueKey('skillsCheckbox'),
      ValueKey('projectsCheckbox'),
    ];

    for (final key in checkboxKeys) {
      final checkbox = find.byKey(key);
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
    }

    await tester.ensureVisible(find.byKey(const ValueKey('checkCvButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('checkCvButton')));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const ValueKey('resultCard')));
    await tester.pumpAndSettle();
    expect(find.text('Score: 100 / 100'), findsOneWidget);
    expect(find.text('Your CV looks ready.'), findsOneWidget);
  });
}
