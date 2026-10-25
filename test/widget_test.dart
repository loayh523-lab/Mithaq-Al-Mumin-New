import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mithaq_al_mumin/main.dart';
import 'package:mithaq_al_mumin/quran/quran_pages.dart';
import 'package:mithaq_al_mumin/features/prayer_calendar_page.dart';
import 'package:mithaq_al_mumin/features/faith_library_pages.dart';
import 'package:mithaq_al_mumin/features/shia_text_library_page.dart';
import 'package:mithaq_al_mumin/features/good_deeds_page.dart';
import 'package:mithaq_al_mumin/features/names_of_allah_page.dart';
import 'package:mithaq_al_mumin/features/qada_tracker_page.dart';
import 'package:mithaq_al_mumin/features/dhikr_fortress_page.dart';
import 'package:mithaq_al_mumin/features/smart_search_page.dart';
import 'package:mithaq_al_mumin/features/faith_services_page.dart';
import 'package:mithaq_al_mumin/features/settings_page.dart';
import 'package:mithaq_al_mumin/features/qibla_page.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:mithaq_al_mumin/features/favorites_page.dart';
import 'package:mithaq_al_mumin/features/rakah_counter_page.dart';
import 'package:mithaq_al_mumin/features/about_support_page.dart';
import 'package:mithaq_al_mumin/services/qibla_calculation.dart';
import 'package:mithaq_al_mumin/services/prayer_notification_service.dart';
import 'package:mithaq_al_mumin/services/app_theme.dart';
import 'package:mithaq_al_mumin/services/prayer_locations.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppTheme.load();
  });

  testWidgets('settings theme switch updates the app and persists the choice', (tester) async {
    await tester.pumpWidget(const MithaqApp());

    expect(AppTheme.isDark.value, isTrue);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Drawer), matching: find.text('الإعدادات')));
    await tester.pumpAndSettle();

    expect(find.text('داكن'), findsOneWidget);
    expect(find.text('فاتح'), findsOneWidget);
    await tester.tap(find.text('فاتح'));
    await tester.pumpAndSettle();

    expect(AppTheme.isDark.value, isFalse);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.light,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('app_theme_dark'), isFalse);
  });

  testWidgets('home prayer-time action opens the prayer calendar rather than settings', (tester) async {
    await tester.pumpWidget(const MithaqApp());
    final prayerTimesAction = find.text('عرض مواقيت الصلوات الخمس');
    expect(prayerTimesAction, findsOneWidget);
    await tester.tap(prayerTimesAction);
    await tester.pumpAndSettle();
    expect(find.text('المواقيت والتقويم'), findsOneWidget);
    expect(find.text('التاريخ الهجري'), findsNothing);
  });

  testWidgets('sections grid does not duplicate the prayer-taqibat library shortcut', (tester) async {
    await tester.pumpWidget(const MithaqApp());
    await tester.tap(find.text('الأقسام').last);
    await tester.pumpAndSettle();

    expect(find.text('الأدعية والزيارات'), findsOneWidget);
    expect(find.text('تعقيبات الصلاة'), findsNothing);
  });

  testWidgets('home and section grid stay inside a narrow phone in both themes', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MithaqApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'dark home dashboard');

    await AppTheme.setDark(false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'light home dashboard');

    await tester.tap(find.text('الأقسام').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'light sections grid');

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'light navigation drawer');
  });

  test('generic prayer-taqibat labels are derived from their own Arabic text', () {
    const first = ShiaTextEntry(
      slug: 'taqib-after-salaat-01',
      title: 'تعقيبات الصلاة',
      alternateName: '',
      type: 'taqibat',
      sourceUrl: '',
      lines: <ShiaTextLine>[
        ShiaTextLine(
          index: 1,
          kind: 'arabic',
          text: 'بسم الله الرحمن الرحيم اللهم إني أسألك من فضلك ورحمتك',
        ),
      ],
    );
    const second = ShiaTextEntry(
      slug: 'taqib-after-salaat-02',
      title: 'تعقيبات الصلاة',
      alternateName: '',
      type: 'taqibat',
      sourceUrl: '',
      lines: <ShiaTextLine>[
        ShiaTextLine(
          index: 1,
          kind: 'arabic',
          text: 'بسم الله الرحمن الرحيم اللهم ارزقني التوفيق لما تحب وترضى',
        ),
      ],
    );

    expect(first.displayTitle, startsWith('تعقيب بعد الصلاة — '));
    expect(second.displayTitle, startsWith('تعقيب بعد الصلاة — '));
    expect(first.displayTitle, isNot(second.displayTitle));
  });

  testWidgets('home screen shows the agreed dashboard and drawer navigation opens tasbeeh', (tester) async {
    await tester.pumpWidget(const MithaqApp());
    expect(find.text('ميثاق المؤمن'), findsWidgets);
    expect(find.text(hijriDateLabel(DateTime.now())), findsOneWidget);
    expect(find.text('الصلاة القادمة'), findsOneWidget);
    expect(find.text('مواقيت الصلاة'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('قبس اليوم'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('قبس اليوم'), findsOneWidget);
    expect(find.text('افتح الآية'), findsOneWidget);
    expect(find.byTooltip('قبس آخر'), findsOneWidget);
    expect(find.byTooltip('نسخ قبس اليوم'), findsOneWidget);
    await tester.tap(find.byTooltip('قبس آخر'));
    await tester.pump();
    expect(find.text('قبس اليوم'), findsOneWidget);
    expect(find.textContaining('سورة'), findsWidgets);
    expect(find.byTooltip('مشاركة قبس اليوم'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('ابدأ وردك'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ابدأ وردك'), findsOneWidget);
    expect(find.text('القرآن الكريم'), findsOneWidget);
    expect(find.text('الأدعية'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('وِرد اليوم'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('وِرد اليوم'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('عمل اليوم'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('عمل اليوم'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.descendant(of: find.byType(Drawer), matching: find.text('التسبيح')),
      180,
      scrollable: find.descendant(of: find.byType(Drawer), matching: find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Drawer), matching: find.text('التسبيح')));
    await tester.pumpAndSettle();
    expect(find.text('التسبيح'), findsOneWidget);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
    await tester.pumpAndSettle();
    expect(find.text('تسبيح الزهراء'), findsOneWidget);
    expect(find.text('تسبيح عام'), findsOneWidget);
    expect(find.text('مراحل التسبيح'), findsOneWidget);
    expect(find.text('34 تكبيرة، ثم 33 تحميدة، ثم 33 تسبيحة'), findsOneWidget);
    expect(find.text('اضغط على الدائرة للتسبيح'), findsOneWidget);
  });
 

  test('Persian-script guard recognizes Persian-specific Unicode characters', () {
    final persianLetter = ShiaTextLine(
      index: 1,
      kind: 'arabic',
      text: String.fromCharCodes([0x06AF]),
    );
    expect(persianLetter.isPersian, isTrue);

    final persianLabel = ShiaTextLine(
      index: 2,
      kind: String.fromCharCodes([0x0641, 0x0627, 0x0631, 0x0633, 0x06CC]),
      text: 'sample',
    );
    expect(persianLabel.isPersian, isTrue);

    final arabicLine = ShiaTextLine(
      index: 3,
      kind: 'arabic',
      text: 'بسم الله الرحمن الرحيم',
    );
    expect(arabicLine.isPersian, isFalse);
  });

  test('exact-alarm permission changes trigger a schedule refresh', () {
    expect(
      PrayerNotificationService.shouldRefreshScheduleForExactAlarmMode(
        exactPermissionGranted: true,
        lastScheduleUsedExactAlarms: false,
      ),
      isTrue,
    );
    expect(
      PrayerNotificationService.shouldRefreshScheduleForExactAlarmMode(
        exactPermissionGranted: false,
        lastScheduleUsedExactAlarms: true,
      ),
      isTrue,
    );
    expect(
      PrayerNotificationService.shouldRefreshScheduleForExactAlarmMode(
        exactPermissionGranted: true,
        lastScheduleUsedExactAlarms: true,
      ),
      isFalse,
    );
    expect(
      PrayerNotificationService.shouldRefreshScheduleForExactAlarmMode(
        exactPermissionGranted: null,
        lastScheduleUsedExactAlarms: false,
      ),
      isFalse,
    );
  });

  test('prayer notification IDs keep early alerts separate from adhan reminders', () {
    expect(PrayerNotificationService.isPrayerReminderNotificationIdForTesting(3999), isFalse);
    expect(PrayerNotificationService.isPrayerReminderNotificationIdForTesting(4000), isTrue);
    expect(PrayerNotificationService.isPrayerReminderNotificationIdForTesting(4004), isTrue);
    expect(PrayerNotificationService.isPrayerReminderNotificationIdForTesting(4005), isFalse);
    expect(PrayerNotificationService.isPrayerReminderNotificationIdForTesting(4009), isFalse);
    expect(PrayerNotificationService.isPrayerReminderNotificationIdForTesting(4010), isTrue);
    expect(PrayerNotificationService.isPrayerReminderNotificationIdForTesting(4294), isTrue);
    expect(PrayerNotificationService.isPrayerReminderNotificationIdForTesting(4295), isFalse);
    expect(PrayerNotificationService.isPrayerReminderNotificationIdForTesting(4299), isFalse);
    expect(PrayerNotificationService.isPrayerReminderNotificationIdForTesting(4300), isFalse);
    expect(PrayerNotificationService.isPrayerNotificationIdForTesting(4000), isTrue);
    expect(PrayerNotificationService.isPrayerNotificationIdForTesting(4005), isFalse);
    expect(PrayerNotificationService.isPrayerNotificationIdForTesting(4010), isTrue);
  });

  testWidgets('drawer groups features and distinguishes the daily actions', (tester) async {
    await tester.pumpWidget(const MithaqApp());
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    final drawerScroll = find.descendant(
      of: find.byType(Drawer),
      matching: find.byType(Scrollable),
    ).first;

    expect(find.text('العبادات'), findsOneWidget);
    final goodDeedsIcon = find.descendant(
      of: find.byType(Drawer),
      matching: find.byIcon(Icons.handshake_rounded),
    );
    await tester.scrollUntilVisible(goodDeedsIcon, 130, scrollable: drawerScroll);
    await tester.pumpAndSettle();
    expect(goodDeedsIcon, findsOneWidget);

    await tester.scrollUntilVisible(
      find.descendant(of: find.byType(Drawer), matching: find.text('الخدمات والمتابعة')),
      180,
      scrollable: drawerScroll,
    );
    await tester.pumpAndSettle();
    expect(find.text('الخدمات والمتابعة'), findsOneWidget);
    for (final icon in [
      Icons.bookmark_added_rounded,
      Icons.event_available_rounded,
    ]) {
      final finder = find.descendant(of: find.byType(Drawer), matching: find.byIcon(icon));
      await tester.scrollUntilVisible(finder, 130, scrollable: drawerScroll);
      await tester.pumpAndSettle();
      expect(finder, findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.descendant(of: find.byType(Drawer), matching: find.text('المعرفة والمناسبات')),
      180,
      scrollable: drawerScroll,
    );
    await tester.pumpAndSettle();
    expect(find.text('المعرفة والمناسبات'), findsOneWidget);
    expect(find.text('نسخة قيد التطوير • راجع المصادر عند الحاجة'), findsOneWidget);
  });

  testWidgets('quick actions adapt to a narrow phone width without layout errors', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MithaqApp());
    await tester.scrollUntilVisible(
      find.text('ابدأ وردك'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('اتجاه القبلة'), findsOneWidget);
    expect(find.text('حصن الأذكار'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    expect(find.text('السور'), findsOneWidget);
    expect(find.text('114'), findsOneWidget);
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

  testWidgets('Qibla compass fits a narrow phone and shows the numeric fallback', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: QiblaPage(compassEvents: Stream<CompassEvent?>.empty()),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('اتجاه القبلة'), findsOneWidget);
    expect(find.text('اتجاه الكعبة المشرفة'), findsOneWidget);
    expect(find.textContaining('من الشمال الجغرافي'), findsOneWidget);
    expect(find.textContaining('قراءة الحساس غير متاحة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Nahj wisdom text follows the active light theme instead of forcing white', (tester) async {
    final theme = ThemeData.light();
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: NahjAlBalaghaPage(),
      ),
    ));
    final quote = tester.widget<Text>(
      find.text('قِيمَةُ كُلِّ امْرِئٍ مَا يُحْسِنُهُ'),
    );
    expect(quote.style?.color, theme.colorScheme.onSurface);
    expect(find.text('فتح نهج البلاغة الكامل عبر المصدر الخارجي'), findsOneWidget);
  });

  testWidgets('prayer countdown uses theme colors in light mode', (tester) async {
    final theme = ThemeData.light();
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: PrayerCalendarPage(),
      ),
    ));
    await tester.pumpAndSettle();
    final nextPrayer = tester.widget<Text>(
      find.textContaining('الصلاة القادمة:').first,
    );
    expect(nextPrayer.style?.color, theme.colorScheme.secondary);
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

  test('estimated prayer times stay ordered and valid for supported Iraq cities', () {
    int minutes(String label) {
      final parts = label.split(':');
      expect(parts.length, 2, reason: label);
      final hour = parts.length == 2 ? int.tryParse(parts[0]) : null;
      final minute = parts.length == 2 ? int.tryParse(parts[1]) : null;
      expect(hour, isNotNull, reason: label);
      expect(minute, isNotNull, reason: label);
      expect(hour ?? -1, inInclusiveRange(0, 23), reason: label);
      expect(minute ?? -1, inInclusiveRange(0, 59), reason: label);
      return (hour ?? 0) * 60 + (minute ?? 0);
    }

    for (final city in PrayerLocations.cities) {
      for (final date in [
        DateTime(2026, 1, 15),
        DateTime(2026, 6, 15),
        DateTime(2026, 10, 24),
      ]) {
        final times = SolarPrayerTimes.forDate(
          date,
          city.latitude,
          city.longitude,
          3.0,
        );
        final ordered = [
          times.fajr,
          times.sunrise,
          times.noon,
          times.asr,
          times.sunset,
          times.maghrib,
          times.isha,
        ].map(minutes).toList();
        for (var i = 1; i < ordered.length; i++) {
          expect(
            ordered[i],
            greaterThan(ordered[i - 1]),
            reason: '${city.name} / ${date.toIso8601String()}',
          );
        }
      }
    }
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
    expect(find.text('الفجر'), findsOneWidget);
    expect(find.textContaining('الصلاة القادمة:'), findsOneWidget);
    await tester.tap(find.text('إمساكية رمضان'));
    await tester.pumpAndSettle();
    expect(find.text('إمساكية تقديرية — قلعة سكر / العراق'), findsOneWidget);
    // Work out the tabular-calendar month length, then verify each row by
    // collecting every visible ListView row while scrolling through the month.
    final reference = DateTime.now();
    final currentHijri = hijriDateParts(reference);
    final targetYear = currentHijri.month > 9
        ? currentHijri.year + 1
        : currentHijri.year;
    DateTime? ramadanStart;
    final scanStart = DateTime(reference.year - 1, 1, 1);
    for (var offset = 0; offset < 800; offset++) {
      final candidate = scanStart.add(Duration(days: offset));
      final parts = hijriDateParts(candidate);
      if (parts.year == targetYear && parts.month == 9 && parts.day == 1) {
        ramadanStart = candidate;
        break;
      }
    }
    expect(ramadanStart, isNotNull);
    var expectedRows = 0;
    for (var offset = 0; offset < 30; offset++) {
      final parts = hijriDateParts(ramadanStart!.add(Duration(days: offset)));
      if (parts.year != targetYear || parts.month != 9) break;
      expectedRows++;
    }
    expect(expectedRows, inInclusiveRange(29, 30));

    final listScroller = find.byType(Scrollable).first;
    final observedDays = <int>{};
    void collectVisibleRamadanDays() {
      for (final textWidget in tester.widgetList<Text>(find.byType(Text))) {
        final label = textWidget.data;
        if (label == null) continue;
        final match = RegExp(r'^رمضان (\d+) — ').firstMatch(label);
        if (match != null) observedDays.add(int.parse(match.group(1)!));
      }
    }

    for (var attempt = 0; attempt < 24 && observedDays.length < expectedRows; attempt++) {
      collectVisibleRamadanDays();
      await tester.drag(listScroller, const Offset(0, -220));
      await tester.pumpAndSettle();
    }
    collectVisibleRamadanDays();
    expect(
      observedDays,
      containsAll(List<int>.generate(expectedRows, (index) => index + 1)),
    );
    expect(observedDays.length, expectedRows);

    // Return to the top before selecting the Hijri calendar tab.
    await tester.fling(listScroller, const Offset(0, 4000), 5000);
    await tester.pumpAndSettle();

    await tester.tap(find.text('التقويم الهجري'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('عرض التقويم السنوي'));
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
    expect(find.byKey(const ValueKey('quran-verse-1-1')), findsOneWidget);
    expect(find.textContaining('الجزء ١'), findsOneWidget);
    expect(find.textContaining('الصفحة'), findsNothing);
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
    final preloaded = await tester.runAsync(() => ShiaTextData.load());
    expect(preloaded, isNotNull);
    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: ShiaTextLibraryPage(
          initialCategory: 'الزيارات الشريفة',
          dataFuture: Future<ShiaTextData>.value(preloaded!),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('الأدعية والزيارات'), findsWidgets);
    expect(find.textContaining('186 نصاً'), findsOneWidget);
    expect(find.textContaining('76 صحيفة ومناجاة'), findsOneWidget);
    expect(find.text('الصحيفة السجادية والمناجيات (76)'), findsOneWidget);
    expect(find.textContaining('25 زيارة'), findsOneWidget);
    expect(find.textContaining('ما قدرنا نحمّل مكتبة الأدعية'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('زيارة عاشوراء'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('زيارة عاشوراء'),
      250,
      scrollable: find.descendant(
        of: find.byType(ListView).last,
        matching: find.byType(Scrollable),
      ).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('زيارة عاشوراء'), findsWidgets);
  });

  testWidgets('combined dua library lets readers filter into Sahifa and Munajat', (tester) async {
    final preloaded = await tester.runAsync(() => ShiaTextData.load());
    expect(preloaded, isNotNull);
    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: ShiaTextLibraryPage(dataFuture: Future<ShiaTextData>.value(preloaded!)),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('186 نصاً'), findsOneWidget);
    await tester.tap(find.text('الصحيفة السجادية والمناجيات (76)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('الدعاء 01: الدعاء في التحميد لله عز وجل'), findsWidgets);
  });

  testWidgets('Sahifa and Munajat remain accessible in their own section', (tester) async {
    final preloaded = await tester.runAsync(() => ShiaTextData.loadSahifa());
    expect(preloaded, isNotNull);
    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: ShiaTextLibraryPage(
          sahifaOnly: true,
          dataFuture: Future<ShiaTextData>.value(preloaded!),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('الصحيفة السجادية والمناجيات'), findsWidgets);
    expect(find.textContaining('76 نصاً محفوظاً'), findsOneWidget);
    expect(find.textContaining('ما قدرنا نحمّل مكتبة الأدعية'), findsNothing);
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
    expect(find.text('حصن الأذكار'), findsOneWidget);
    expect(find.text('أقسام الأذكار'), findsOneWidget);
    expect(find.textContaining('التسبيحات'), findsWidgets);
    expect(find.textContaining('المناجاة'), findsWidgets);
    expect(find.textContaining('العوذات'), findsWidgets);
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
    expect(find.text('استفتاءات السيد علي الخامنئي'), findsOneWidget);
    expect(find.text('استفتاءات السيد علي السيستاني'), findsOneWidget);
    // The services list is longer than the test viewport; scroll each target
    // tile into view instead of assuming every ListView child is mounted immediately.
    await tester.scrollUntilVisible(
      find.text('تفسير القرآن الكريم'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('تفسير القرآن الكريم'), findsOneWidget);
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
    await tester.scrollUntilVisible(
      find.text('خيارات الأذان المتقدمة'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('خيارات الأذان المتقدمة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('خيارات الأذان المتقدمة'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('حتى يوصل الأذان والتطبيق مغلق'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('حتى يوصل الأذان والتطبيق مغلق'), findsOneWidget);
    expect(find.textContaining('Phone Master أو Battery Lab'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1600));
    await tester.pumpAndSettle();

    final settingsScroll = find.descendant(
      of: find.byType(SettingsPage),
      matching: find.byType(Scrollable),
    ).first;
    final fajrSwitch = find.byKey(const ValueKey('prayer_enabled_fajr'));
    await tester.scrollUntilVisible(
      fajrSwitch,
      220,
      scrollable: settingsScroll,
    );
    await tester.pumpAndSettle();
    await tester.tap(fajrSwitch);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('prayer_enabled_fajr'), isFalse);

    final earlySwitch = find.widgetWithText(
      SwitchListTile,
      'تنبيه قبل الأذان',
    );
    await tester.scrollUntilVisible(
      earlySwitch,
      220,
      scrollable: settingsScroll,
    );
    await tester.pumpAndSettle();
    await tester.tap(earlySwitch);
    await tester.pumpAndSettle();
    expect(prefs.getBool('prayer_early_alert_enabled'), isTrue);

    final minutesPicker = find.byKey(
      const ValueKey('prayer_early_alert_minutes'),
    );
    await tester.scrollUntilVisible(
      minutesPicker,
      220,
      scrollable: settingsScroll,
    );
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
    await tester.scrollUntilVisible(
      find.text('خدمة العملاء'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('خدمة العملاء'), findsOneWidget);
    expect(find.text('إرسال البلاغ'), findsOneWidget);
    expect(find.text('الحسابات الرسمية'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('مشاركة ميثاق المؤمن'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('مشاركة ميثاق المؤمن'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('الدعم الفني والإبلاغ عن مشكلة'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('الدعم الفني والإبلاغ عن مشكلة'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('مصدر نص القرآن — Tanzil'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('مصدر نص القرآن — Tanzil'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('الأذان من العتبة العلوية المقدسة بصوت الشيخ شبّر معلة'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('الأذان من العتبة العلوية المقدسة بصوت الشيخ شبّر معلة'), findsOneWidget);
  });

  testWidgets('smart search screen offers cross-library offline search', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: SmartSearchPage()),
    ));
    expect(find.text('الباحث الذكي'), findsOneWidget);
    expect(find.textContaining('ابحث في القرآن والأدعية والزيارات'), findsOneWidget);
  });

}
