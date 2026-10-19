import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_al_mumin/main.dart';

void main() {
  testWidgets('home screen renders and navigation opens tasbeeh', (tester) async {
    await tester.pumpWidget(const MithaqApp());
    expect(find.text('ميثاق المؤمن'), findsOneWidget);
    expect(find.text('الوصول السريع'), findsOneWidget);
    await tester.tap(find.text('التسبيح').last);
    await tester.pumpAndSettle();
    expect(find.text('اضغط على الدائرة لزيادة العدّاد'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}
