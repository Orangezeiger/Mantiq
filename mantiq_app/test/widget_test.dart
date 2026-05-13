import 'package:flutter_test/flutter_test.dart';
import 'package:mantiq_app/main.dart';

void main() {
  testWidgets('App startet ohne Fehler', (WidgetTester tester) async {
    await tester.pumpWidget(const MantiqApp());
    expect(find.byType(MantiqApp), findsOneWidget);
  });
}
