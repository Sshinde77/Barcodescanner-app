import 'package:flutter_test/flutter_test.dart';
import 'package:smart_barcode_manager/app.dart';

void main() {
  testWidgets('app launches landing scanner', (tester) async {
    await tester.pumpWidget(const SmartBarcodeManagerApp());
    await tester.pumpAndSettle();

    expect(find.text('Smart Barcode Manager'), findsWidgets);
    expect(find.text('Scan Barcode'), findsOneWidget);
  });
}
