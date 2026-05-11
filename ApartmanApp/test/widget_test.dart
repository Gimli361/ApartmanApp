import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apartman_app/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ApartmanApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Login ekranının yüklendiğini kontrol et
    expect(find.text('Giriş Yap'), findsOneWidget);
  });
}
