import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mithaq_al_mumin/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home screen renders and navigation opens tasbeeh', (tester) async {
    await tester.pumpWidget(const MithaqApp());
    expect(find.text('ميثاق المؤمن'), findsOneWidget);
    expect(find.text('الوصول السريع'), findsOneWidget);
    await tester.tap(find.text('التسبيح').last);
    await tester.pumpAndSettle();
    expect(find.text('اضغط على الدائرة لزيادة العدّاد'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('Quran index loads the bundled 114-surah catalog', (tester) async {
    await tester.pumpWidget(const MithaqApp());
    await tester.tap(find.text('القرآن الكريم').last);
    await tester.pumpAndSettle();
    expect(find.text('فهرس السور'), findsOneWidget);
    expect(find.text('114 سورة • 6236 آية'), findsOneWidget);
    expect(find.text('الفاتحة'), findsOneWidget);
  });

  testWidgets('prayer tracker records a checked prayer', (tester) async {
    await tester.pumpWidget(const MithaqApp());
    await tester.ensureVisible(find.text('متابعة الصلاة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('متابعة الصلاة'));
    await tester.pumpAndSettle();
    expect(find.text('0/5'), findsOneWidget);
    await tester.tap(find.text('الفجر'));
    await tester.pumpAndSettle();
    expect(find.text('1/5'), findsOneWidget);
  });

  testWidgets('khatma tracker opens and records completed juz', (tester) async {
    await tester.pumpWidget(const MithaqApp());
    await tester.ensureVisible(find.text('ختمة القرآن'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ختمة القرآن'));
    await tester.pumpAndSettle();
    expect(find.text('/ 30 جزءاً'), findsOneWidget);
    await tester.tap(find.text('إكمال جزء'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    expect(find.text('الخطوة التالية'), findsOneWidget);
  });
}
