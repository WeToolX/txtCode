// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:txtcode/main.dart';

void main() {
  testWidgets('Main screen renders key controls', (WidgetTester tester) async {
    await tester.pumpWidget(const TxtCodeApp());

    expect(find.text('文本扰动'), findsOneWidget);
    expect(find.text('原始文本'), findsOneWidget);
    expect(find.text('执行转换'), findsOneWidget);
  });
}
