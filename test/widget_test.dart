import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_al_mumin/main.dart';

void main() {
  testWidgets('fresh home screen renders', (tester) async {
    await tester.pumpWidget(const MithaqApp());
    await tester.pumpAndSettle();

    expect(find.text('ميثاق المؤمن'), findsOneWidget);
    expect(find.text('أهلاً بك'), findsOneWidget);
    await tester.ensureVisible(find.text('الوصول السريع'));
    await tester.pumpAndSettle();
    expect(find.text('الوصول السريع'), findsOneWidget);
    expect(find.text('القرآن الكريم'), findsWidgets);
  });

  testWidgets('bottom navigation opens tasbeeh placeholder', (tester) async {
    await tester.pumpWidget(const MithaqApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('التسبيح').last);
    await tester.pumpAndSettle();

    expect(find.text('هذه صفحة مبدئية ضمن هيكل التطبيق الجديد.'), findsOneWidget);
  });
}
