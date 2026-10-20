import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mithaq_al_mumin/main.dart';
import 'package:mithaq_al_mumin/quran/quran_pages.dart';
import 'package:mithaq_al_mumin/features/prayer_calendar_page.dart';
import 'package:mithaq_al_mumin/features/mafatih_library_page.dart';
import 'package:mithaq_al_mumin/features/shia_text_library_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home screen shows the agreed dashboard and drawer navigation opens tasbeeh', (tester) async {
    await tester.pumpWidget(const MithaqApp());
    expect(find.text('ميثاق المؤمن'), findsOneWidget);
    expect(find.text('التاريخ الهجري'), findsOneWidget);
    expect(find.text('الصلاة القادمة'), findsOneWidget);
    expect(find.text('مواقيت الصلوات'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('عمل اليوم'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('عمل اليوم'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التسبيح'));
    await tester.pumpAndSettle();
    expect(find.text('اضغط على الدائرة للتسبيح'), findsOneWidget);
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

  testWidgets('prayer tracker records a checked prayer from the drawer', (tester) async {
    await tester.pumpWidget(const MithaqApp());
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('متابعة الصلاة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('متابعة الصلاة'));
    await tester.pumpAndSettle();
    expect(find.text('0/5'), findsOneWidget);
    await tester.tap(find.text('الفجر'));
    await tester.pumpAndSettle();
    expect(find.text('1/5'), findsOneWidget);
  });

  testWidgets('khatma tracker opens and records completed juz from the drawer', (tester) async {
    await tester.pumpWidget(const MithaqApp());
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
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
    expect(find.textContaining('الصلاة القادمة:'), findsOneWidget);
    await tester.tap(find.text('إمساكية رمضان'));
    await tester.pumpAndSettle();
    expect(find.text('إمساكية تقديرية — قلعة سكر / العراق'), findsOneWidget);
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
    // Wait for the asynchronous asset read and the full-text scan to finish.
    // A fixed short delay is flaky on slower CI runners because the Quran corpus
    // contains 6,236 verses and each verse is normalized before matching.
    await tester.pump();
    var finished = false;
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      if (find.textContaining('النتائج الأولى').evaluate().isNotEmpty ||
          find.textContaining('ما لقينا آيات مطابقة').evaluate().isNotEmpty ||
          find.textContaining('تعذّر فتح ملف القرآن المحلي').evaluate().isNotEmpty) {
        finished = true;
        break;
      }
    }
    expect(finished, isTrue, reason: 'Quran search did not leave its loading state.');
    expect(find.textContaining('النتائج الأولى'), findsOneWidget);
    expect(find.textContaining('الفاتحة • الآية 2'), findsOneWidget);
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
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('الآيات المحفوظة'), findsOneWidget);
    expect(find.textContaining('ما عندك آيات محفوظة'), findsOneWidget);
  });


  testWidgets('Shia dua library opens its offline collection', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: ShiaTextLibraryPage()),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 700)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('الأدعية والزيارات'), findsWidgets);
    expect(find.textContaining('72 نصاً'), findsOneWidget);
    expect(find.textContaining('ما قدرنا نحمّل مكتبة الأدعية'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('زيارة عاشوراء'),
      300,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ).first,
    );
    expect(find.text('زيارة عاشوراء'), findsWidgets);
  });
}
