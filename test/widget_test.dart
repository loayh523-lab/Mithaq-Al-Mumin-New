import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mithaq_al_mumin/main.dart';
import 'package:mithaq_al_mumin/quran/quran_pages.dart';
import 'package:mithaq_al_mumin/features/prayer_calendar_page.dart';
import 'package:mithaq_al_mumin/features/shia_text_library_page.dart';
import 'package:mithaq_al_mumin/features/good_deeds_page.dart';
import 'package:mithaq_al_mumin/features/names_of_allah_page.dart';
import 'package:mithaq_al_mumin/features/qada_tracker_page.dart';
import 'package:mithaq_al_mumin/features/dhikr_fortress_page.dart';
import 'package:mithaq_al_mumin/features/smart_search_page.dart';
import 'package:mithaq_al_mumin/features/faith_services_page.dart';
import 'package:mithaq_al_mumin/features/settings_page.dart';
import 'package:mithaq_al_mumin/features/favorites_page.dart';
import 'package:mithaq_al_mumin/features/rakah_counter_page.dart';
import 'package:mithaq_al_mumin/features/about_support_page.dart';
import 'package:mithaq_al_mumin/services/qibla_calculation.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home screen shows the agreed dashboard and drawer navigation opens tasbeeh', (tester) async {
    await tester.pumpWidget(const MithaqApp());
    expect(find.text('ميثاق المؤمن'), findsWidgets);
    expect(find.text('التاريخ الهجري'), findsOneWidget);
    expect(find.text('قبس اليوم'), findsOneWidget);
    expect(find.text('ابدأ وردك'), findsOneWidget);
    expect(find.text('وِرد اليوم'), findsOneWidget);
    expect(find.text('القرآن الكريم'), findsOneWidget);
    expect(find.text('الأدعية'), findsOneWidget);
    expect(find.text('الصلاة القادمة'), findsNothing);
    expect(find.text('مواقيت الصلوات'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('عمل اليوم'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('عمل اليوم'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Drawer), matching: find.text('التسبيح والعداد')));
    await tester.pumpAndSettle();
    expect(find.text('التسبيح'), findsOneWidget);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
    await tester.pumpAndSettle();
    expect(find.text('تسبيح الزهراء'), findsOneWidget);
    expect(find.text('تسبيح عام'), findsOneWidget);
    expect(find.text('مراحل تسبيح الزهراء عليها السلام'), findsOneWidget);
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

  test('Dua categories prioritize specific collections over broad date heuristics', () {
    const sahifaMunajat = ShiaTextEntry(
      slug: 'sahifa-sajjadiya-munajat',
      title: 'مناجاة',
      alternateName: '',
      type: 'dua',
      sourceUrl: '',
      lines: <ShiaTextLine>[],
    );
    const fridayArafah = ShiaTextEntry(
      slug: 'dua-friday-arafah',
      title: 'دعاء الجمعة في عرفة',
      alternateName: '',
      type: 'dua',
      sourceUrl: '',
      lines: <ShiaTextLine>[],
    );
    const munajat = ShiaTextEntry(
      slug: 'munajat-15',
      title: 'مناجاة',
      alternateName: '',
      type: 'dua',
      sourceUrl: '',
      lines: <ShiaTextLine>[],
    );
    expect(sahifaMunajat.category, 'الصحيفة السجادية والمناجيات');
    expect(fridayArafah.category, 'الأعمال والمناسبات');
    expect(munajat.category, 'الصحيفة السجادية والمناجيات');
  });

  test('prayer times are displayed in a readable 12-hour Arabic format', () {
    expect(formatPrayerTime12Hour('00:05'), '12:05 ص');
    expect(formatPrayerTime12Hour('08:15'), '8:15 ص');
    expect(formatPrayerTime12Hour('12:07'), '12:07 م');
    expect(formatPrayerTime12Hour('13:09'), '1:09 م');
    expect(formatPrayerTime12Hour('23:59'), '11:59 م');
    expect(formatPrayerTime12Hour('not-a-time'), 'not-a-time');
  });

  test('Hijri civil conversion matches the expected date for 20 October 2026', () {
    expect(hijriDateLabel(DateTime(2026, 10, 20)), '٨ جمادى الأولى ١٤٤٨ هـ');
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

    await tester.tap(find.text('التقويم السنوي'));
    await tester.pumpAndSettle();
    expect(find.text('التقويم السنوي ${DateTime.now().year}'), findsOneWidget);
    await tester.tap(find.text('كانون الثاني'));
    await tester.pumpAndSettle();
    expect(find.text('1 كانون الثاني ${DateTime.now().year} م'), findsOneWidget);
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
      home: Directionality(textDirection: TextDirection.rtl, child: ShiaTextLibraryPage(initialCategory: 'الزيارات الشريفة')),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 700)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('الأدعية والزيارات'), findsWidgets);
    expect(find.textContaining('نصاً • منها'), findsOneWidget);
    expect(find.textContaining('ما قدرنا نحمّل مكتبة الأدعية'), findsNothing);
    expect(find.text('زيارة عاشوراء'), findsWidgets);
  });
  testWidgets('good deeds checklist saves checked items locally', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: GoodDeedsPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('صالح الأعمال'), findsOneWidget);
    await tester.tap(find.text('ورد من القرآن الكريم'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 من '), findsOneWidget);
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
    expect(find.text('أذكار الصباح والمساء'), findsOneWidget);
    expect(find.text('أذكار الصباح'), findsOneWidget);
    await tester.tap(find.text('أذكار المساء'));
    await tester.pumpAndSettle();
    expect(find.text('الصلاة على النبي وآله'), findsOneWidget);
  });

  testWidgets('faith services page shows verified sources and safe guide entry points', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: FaithServicesPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('الخدمات الإيمانية'), findsOneWidget);
    expect(find.text('فقه المؤمن — المسائل الشرعية'), findsOneWidget);
    expect(find.text('تفسير القرآن الكريم'), findsOneWidget);
    // The services list is longer than the test viewport; scroll the target tile
    // into view instead of assuming every ListView child is mounted immediately.
    await tester.scrollUntilVisible(
      find.text('الاستخارة القرآنية — إرشاد شرعي'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('الاستخارة القرآنية — إرشاد شرعي'), findsOneWidget);
  });

  testWidgets('dua and ziyarat reader saves favorites locally', (tester) async {
    const entry = ShiaTextEntry(
      slug: 'test-ziyara-favorite',
      title: 'زيارة للاختبار',
      alternateName: '',
      type: 'ziyara',
      sourceUrl: '',
      lines: <ShiaTextLine>[
        ShiaTextLine(index: 1, kind: 'arabic', text: 'السلام عليكم'),
      ],
    );
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: ShiaTextReaderPage(entry: entry)),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byTooltip('إضافة إلى المفضلة'), findsOneWidget);
    await tester.tap(find.byTooltip('إضافة إلى المفضلة'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('favorite_shia_text_slugs'),
      contains('test-ziyara-favorite'),
    );
    expect(find.text('أُضيف النص إلى المفضلة المباركة'), findsOneWidget);
  });

  testWidgets('favorites page provides an offline empty state', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: FavoritesPage(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('المفضلة المباركة'), findsOneWidget);
    expect(find.text('مفضلتك فارغة حالياً'), findsOneWidget);
    expect(find.text('تصفح الأدعية والزيارات'), findsOneWidget);
  });

  testWidgets('manual rakah counter tracks sajdahs and persists progress', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: RakahCounterPage(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('الركعة 1 من 4'), findsOneWidget);
    await tester.ensureVisible(find.text('تسجيل السجدة الأولى'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل السجدة الأولى'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.ensureVisible(find.text('تسجيل السجدة الثانية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل السجدة الثانية'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.ensureVisible(find.text('الركعة التالية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الركعة التالية'));
    await tester.pumpAndSettle();
    expect(find.text('الركعة 2 من 4'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('rakah_helper_current'), 2);
    expect(prefs.getInt('rakah_helper_sajdahs'), 0);
  });

  testWidgets('settings save per-prayer reminders and pre-prayer alert options', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: SettingsPage()),
      ),
    ));
    await tester.pumpAndSettle();

    final fajrSwitch = find.byKey(const ValueKey('prayer_enabled_fajr'));
    await tester.ensureVisible(fajrSwitch);
    await tester.pumpAndSettle();
    await tester.tap(fajrSwitch);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('prayer_enabled_fajr'), isFalse);

    final earlySwitch = find.widgetWithText(
      SwitchListTile,
      'تنبيه قبل الأذان',
    );
    await tester.ensureVisible(earlySwitch);
    await tester.pumpAndSettle();
    await tester.tap(earlySwitch);
    await tester.pumpAndSettle();
    expect(prefs.getBool('prayer_early_alert_enabled'), isTrue);

    final minutesPicker = find.byKey(
      const ValueKey('prayer_early_alert_minutes'),
    );
    await tester.ensureVisible(minutesPicker);
    await tester.pumpAndSettle();
    await tester.tap(minutesPicker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('10 دقائق').last);
    await tester.pumpAndSettle();
    expect(prefs.getInt('prayer_early_alert_minutes'), 10);
  });

  testWidgets('about and support page shows sharing and source information', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: AboutSupportPage()),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('عن التطبيق والدعم'), findsOneWidget);
    expect(find.text('ميثاق المؤمن'), findsOneWidget);
    expect(find.text('مشاركة ميثاق المؤمن'), findsOneWidget);
    expect(find.text('الدعم الفني والإبلاغ عن مشكلة'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('مصدر نص القرآن — Tanzil'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('مصدر نص القرآن — Tanzil'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('لم نتحقق من مطابقته لألفاظ الأذان الجعفري'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('لم نتحقق من مطابقته لألفاظ الأذان الجعفري'), findsOneWidget);
  });

  testWidgets('smart search screen offers cross-library offline search', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: SmartSearchPage()),
    ));
    expect(find.text('الباحث الذكي'), findsOneWidget);
    expect(find.textContaining('ابحث في القرآن والأدعية والزيارات'), findsOneWidget);
  });

}
