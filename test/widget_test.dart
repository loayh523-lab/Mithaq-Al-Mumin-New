import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mithaq_al_mumin/main.dart';
import 'package:mithaq_al_mumin/quran/quran_pages.dart';
import 'package:mithaq_al_mumin/features/prayer_calendar_page.dart';
import 'package:mithaq_al_mumin/features/mafatih_library_page.dart';
import 'package:mithaq_al_mumin/quran/quran_pages.dart' show QuranSearchPage, QuranBookmarksPage;

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
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: QuranIndexPage()),
      ),
    ));
    // AssetBundle I/O uses real asynchronous work; allow it to finish outside fake time.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('فهرس السور'), findsOneWidget);
    expect(find.textContaining('114 سورة'), findsOneWidget);
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

  testWidgets('prayer calendar shows estimated times and imsakiyah switch', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: PrayerCalendarPage(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('المواقيت والتقويم'), findsOneWidget);
    expect(find.text('الفجر (تقديري)'), findsOneWidget);
    await tester.tap(find.text('إمساكية رمضان'));
    await tester.pumpAndSettle();
    expect(find.text('إمساكية تقديرية لقلعة سكر / ذي قار'), findsOneWidget);
    expect(find.textContaining('الإمساك/الفجر:'), findsWidgets);
  });

  testWidgets('surah reader opens its bundled text without internet', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: SurahReaderPage(
          surah: SurahInfo(
            id: 1,
            name: 'الفاتحة',
            transliteration: 'Al-Faatiha',
            type: 'meccan',
            totalVerses: 7,
          ),
        ),
      ),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('الفاتحة'), findsWidgets);
    expect(find.textContaining('7 آية'), findsOneWidget);
    expect(find.textContaining('تعذّر فتح نص القرآن'), findsNothing);
  });


  testWidgets('Quran full-text search returns offline verse matches', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: QuranSearchPage()),
    ));
    await tester.enterText(find.byType(TextField), 'الحمد');
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 450)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('الفاتحة • الآية 2'), findsOneWidget);
    expect(find.textContaining('النتائج الأولى'), findsOneWidget);
  });

  testWidgets('Mafatih library opens its bundled offline catalog', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: MafatihLibraryPage()),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('مفاتيح الجنان'), findsWidgets);
    expect(find.text('ما قدرنا نحمّل مكتبة مفاتيح الجنان'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Quran bookmarks page shows a clear empty state', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: QuranBookmarksPage()),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('الآيات المحفوظة'), findsOneWidget);
    expect(find.textContaining('ما عندك آيات محفوظة'), findsOneWidget);
  });
}
