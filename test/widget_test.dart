import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:govscheme_pro/widgets/status_chip.dart';

void main() {
  testWidgets('StatusChip renders its label', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: StatusChip('Ongoing'))),
    ));

    expect(find.text('Ongoing'), findsOneWidget);
  });
}
