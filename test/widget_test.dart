import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quiet_route_demo/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QuietRouteApp());

    expect(find.text('Quiet Route'), findsWidgets);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
