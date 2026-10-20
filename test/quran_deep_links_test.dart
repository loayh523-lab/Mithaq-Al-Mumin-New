import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mithaq_al_mumin/quran/quran_pages.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
