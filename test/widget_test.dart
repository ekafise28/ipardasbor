import 'package:flutter_test/flutter_test.dart';
import 'package:ipardasbor/app/app.dart';

void main() {
  testWidgets('Aplikasi menampilkan splash screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const IparApp());

    expect(find.text('I-PAR MOBILE'), findsOneWidget);
    expect(find.text('Sistem Pengawasan Pariwisata'), findsOneWidget);
  });
}
