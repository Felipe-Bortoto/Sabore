import 'package:flutter_test/flutter_test.dart';

import 'package:sabore/main.dart';

void main() {
  testWidgets('shows app shell and loading state', (WidgetTester tester) async {
    await tester.pumpWidget(const SaboreApp());

    expect(find.text('Saborê'), findsOneWidget);
    expect(find.text('Favoritos'), findsOneWidget);
    expect(find.text('Carregando receitas...'), findsOneWidget);
  });
}
