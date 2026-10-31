import 'package:flutter_test/flutter_test.dart';
import 'package:pedebook_app/main.dart';

void main() {
  testWidgets('PedebookApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PedebookApp());
    expect(find.text('Pedebook'), findsOneWidget);
  });
}
