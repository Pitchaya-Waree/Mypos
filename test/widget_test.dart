import 'package:flutter_test/flutter_test.dart';
import 'package:booth_pos_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    expect(const BoothPosApp(), isNotNull);
  });
}
