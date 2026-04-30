import 'package:flutter_test/flutter_test.dart';
import 'package:powerlog/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const PowerLogApp());
    expect(find.text('PowerLog'), findsOneWidget);
  });
}
