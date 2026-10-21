import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mithaq_al_mumin/quran/quran_pages.dart';
import 'package:mithaq_al_mumin/quran/quran_parts.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Hafs Quran divisions have all 30 juz and 60 hizbs', () {
    expect(quranJuzStartAyahIds.length, 30);
    expect(quranHizbStartAyahIds.length, 60);
    expect(quranJuzStartAyahIds.first, 1);
    expect(quranJuzStartAyahIds[1], 149);
    expect(quranJuzStartAyahIds.last, 5673);
    expect(quranHizbStartAyahIds.first, 1);
    expect(quranHizbStartAyahIds[1], 82);
    expect(quranHizbStartAyahIds.last, 5949);
  });

  testWidgets('Quran index switches between surahs, juz and hizbs', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: QuranIndexPage()),
      ),
    ));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('الأجزاء'));
    await tester.pump();
    expect(find.text('الجزء 1'), findsOneWidget);
    expect(find.textContaining('بداية القراءة: الفاتحة'), findsOneWidget);

    await tester.tap(find.text('الأحزاب'));
    await tester.pump();
    expect(find.text('الحزب 1'), findsOneWidget);
    expect(find.textContaining('بداية القراءة: الفاتحة'), findsOneWidget);
  });

  testWidgets('reader opens at and highlights a requested Quran verse', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const surah = SurahInfo(
      id: 1,
      name: 'الفاتحة',
      transliteration: 'Al-Fatiha',
      type: 'meccan',
      totalVerses: 7,
    );

    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: SurahReaderPage(surah: surah, initialVerse: 3),
      ),
    ));

    // Wait for the real bundled Quran asset to be loaded outside fake async.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 350)),
    );
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 80));

    final target = find.byKey(const ValueKey('quran-verse-1-3'));
    expect(target, findsOneWidget);
    final targetBox = find.descendant(
      of: target,
      matching: find.byType(Container),
    ).first;
    final targetRect = tester.getRect(targetBox);
    expect(targetRect.top, greaterThanOrEqualTo(0));
    expect(targetRect.top, lessThan(tester.view.physicalSize.height));
    expect(find.text('الفاتحة'), findsOneWidget);
  });
}
