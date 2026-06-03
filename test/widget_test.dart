import 'package:flutter_test/flutter_test.dart';

import 'package:careerkit_mobile/main.dart';

void main() {
  testWidgets('renders CareerKit dashboard', (tester) async {
    await tester.pumpWidget(const CareerKitApp());

    expect(find.text('CareerKit Dashboard'), findsOneWidget);
    expect(find.text('Create Career Profile'), findsOneWidget);
    expect(find.text('Save Profile to Backend', skipOffstage: false),
        findsOneWidget);
  });
}
