import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mithaq_al_mumin/main.dart';
import 'package:mithaq_al_mumin/quran/quran_pages.dart';
import 'package:mithaq_al_mumin/features/prayer_calendar_page.dart';
import 'package:mithaq_al_mumin/features/mafatih_library_page.dart';
import 'package:mithaq_al_mumin/features/shia_text_library_page.dart';
import 'package:mithaq_al_mumin/features/good_deeds_page.dart';
import 'package:mithaq_al_mumin/features/names_of_allah_page.dart';
import 'package:mithaq_al_mumin/features/qada_tracker_page.dart';
import 'package:mithaq_al_mumin/features/dhikr_fortress_page.dart';
import 'package:mithaq_al_mumin/features/smart_search_page.dart';
import 'package:mithaq_al_mumin/services/qibla_calculation.dart';

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
    await tester.scrollUntilVisible(
      find.text('متابعة الصلاة'),
      250,
      scrollable: find.descendant(of: find.byType(Drawer), matching: find.byType(Scrollable)).first,
    );
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
    await tester.scrollUntilVisible(
      find.text('ختمة القرآن'),
      250,
      scrollable: find.descendant(of: find.byType(Drawer), matching: find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ختمة القرآن'));
    await tester.pumpAndSettle();
    expect(find.text('/ 30 جزءاً'), findsOneWidget);
    await tester.tap(find.text('إكمال جزء'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    expect(find.text('الخطوة التالية'), findsOneWidget);
  });

  test('Qibla bearing and magnetic correction use the proper north reference', () {
    expect(
      qiblaBearingDegrees(latitude: 0, longitude: 39.8262),
      closeTo(0, 0.01),
    );
    expect(
      magneticQiblaBearingDegrees(trueBearing: 15, declinationDegrees: 20),
      closeTo(355, 0.0001),
    );
    expect(
      magneticQiblaBearingDegrees(trueBearing: 355, declinationDegrees: -10),
      closeTo(5, 0.0001),
    );
    final declination = magneticDeclinationDegrees(
      latitude: 31.85,
      longitude: 46.07,
      date: DateTime(2026, 10, 20),
    );
    expect(declination.isFinite, isTrue);
    expect(declination, inInclusiveRange(-180, 180));
  });

  test('Hijri civil conversion matches the expected date for 20 October 2026', () {
    expect(hijriDateLabel(DateTime(2026, 10, 20)), '8 جمادى الأولى 1448 هـ');
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
      home: Directionality(textDirection: TextDirection.rtl, child: ShiaTextLibraryPage(initialCategory: 'الزيارات')),
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
  testWidgets('good deeds checklist saves checked items locally', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: GoodDeedsPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('صالح الأعمال'), findsOneWidget);
    await tester.tap(find.text('قراءة القرآن الكريم'));
    await tester.pumpAndSettle();
    expect(find.text('1 من 10 أعمال'), findsOneWidget);
  });

  testWidgets('Names of Allah opens its Arabic offline list', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: NamesOfAllahPage()),
    ));
    expect(find.text('أسماء الله الحسنى'), findsOneWidget);
    expect(find.text('الرحمن'), findsOneWidget);
  });

  testWidgets('qada tracker shows independent prayer and fasting counters', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: QadaTrackerPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('سجل القضاء'), findsOneWidget);
    expect(find.text('صلاة الصبح'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('صيام القضاء'),
      250,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    expect(find.text('صيام القضاء'), findsOneWidget);
  });

  testWidgets('dhikr fortress switches between morning and evening counters', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: DhikrFortressPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('حصن الأذكار'), findsOneWidget);
    expect(find.text('أذكار الصباح'), findsOneWidget);
    await tester.tap(find.text('أذكار المساء'));
    await tester.pumpAndSettle();
    expect(find.text('الصلاة على محمد وآل محمد'), findsOneWidget);
  });

  testWidgets('smart search screen offers cross-library offline search', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: SmartSearchPage()),
    ));
    expect(find.text('الباحث الذكي'), findsOneWidget);
    expect(find.textContaining('ابحث في القرآن والأدعية والزيارات'), findsOneWidget);
  });

}
