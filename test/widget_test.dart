import 'package:flutter_test/flutter_test.dart';

import 'package:sabore/main.dart';

void main() {
  testWidgets('shows search screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SaboreApp());

    expect(find.text('Saborê'), findsOneWidget);
    expect(find.text('Qual receita você procura?'), findsOneWidget);
    expect(find.text('Pesquisar'), findsOneWidget);
  });
}
