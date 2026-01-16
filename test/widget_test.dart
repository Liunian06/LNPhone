import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lnphone2/main.dart';

void main() {
  testWidgets('LnPhone app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LnPhoneApp());

    // 验证应用启动正常
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
