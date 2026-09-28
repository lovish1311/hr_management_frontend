import 'package:flutter_test/flutter_test.dart';
import 'package:hr_management/app/app.dart';
import 'helpers/test_app_wrapper.dart';

void main() {
  setUp(() async {
    await TestAppWrapper.setup();
  });

  testWidgets('HRManagementApp initializes without unhandled exceptions', (tester) async {
    await tester.pumpWidget(const HRManagementApp());
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });
}
