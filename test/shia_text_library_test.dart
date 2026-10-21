import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_al_mumin/features/shia_text_library_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Arabic dua and ziyara library has readable source-linked content', () async {
    final data = await ShiaTextData.load();

    expect(data.entries, isNotEmpty);
    expect(data.entries.any((entry) => entry.category == 'الزيارات'), isTrue);
    expect(data.entries.any((entry) => entry.category == 'أدعية الصباح'), isTrue);
    expect(data.entries.any((entry) => entry.category == 'الأذكار المشتركة'), isTrue);
    expect(data.entries.any((entry) => entry.isSahifa), isTrue);
    expect(data.entries.every((entry) => entry.arabicText.trim().isNotEmpty), isTrue);

    // The current bundled source is the Arabic Shia-library dataset.
    // Do not mislabel it as Mafatih al-Jinan or fabricate chapter citations.
    for (final entry in data.entries) {
      expect(entry.sourceLabel, 'مكتبة ثقلين الإلكترونية', reason: entry.slug);
      expect(entry.sourceUrl, isNotEmpty, reason: 'Missing source URL: ${entry.slug}');
      expect(
        entry.lines.every((line) => line.kind.toLowerCase() == 'arabic'),
        isTrue,
        reason: 'Only Arabic recitation lines may be bundled: ${entry.slug}',
      );
      expect(
        RegExp(r'[A-Za-zپچژگ]').hasMatch(entry.displayTitle),
        isFalse,
        reason: 'Entry title is not Arabic-only: ${entry.slug}',
      );
      expect(
        containsPersianLanguageMarkers(entry.displayTitle),
        isFalse,
        reason: 'Persian-language title marker found: ${entry.slug}',
      );
      expect(
        RegExp(r'[پچژگ]').hasMatch(entry.sourceLabel),
        isFalse,
        reason: 'Persian-script source label found: ${entry.slug}',
      );
      for (final line in entry.lines.where((line) => line.isArabic)) {
        expect(
          RegExp(r'[پچژگ]').hasMatch(line.text),
          isFalse,
          reason: 'Persian-script character found in Arabic content: ${entry.slug}, line ${line.index}',
        );
        expect(
          containsPersianLanguageMarkers(line.text),
          isFalse,
          reason: 'Persian-language marker found in Arabic content: ${entry.slug}, line ${line.index}',
        );
      }
    }
  });

  test('morning-only and combined morning/evening invocations stay distinct', () {
    const morning = ShiaTextEntry(
      slug: 'dua-sabah',
      title: 'دعاء الصباح',
      alternateName: 'دعاء الصباح',
      type: 'dua',
      sourceUrl: '',
      lines: <ShiaTextLine>[
        ShiaTextLine(index: 1, kind: 'arabic', text: 'بسم الله الرحمن الرحيم'),
      ],
    );
    const combined = ShiaTextEntry(
      slug: 'sahifa-sajjadiya-his-supplication-in-the-morning-and-evening',
      title: 'دعاؤه عند الصباح والمساء',
      alternateName: 'دعاؤه عند الصباح والمساء',
      type: 'dua',
      sourceUrl: '',
      lines: <ShiaTextLine>[
        ShiaTextLine(index: 1, kind: 'arabic', text: 'بسم الله الرحمن الرحيم'),
      ],
    );

    expect(morning.category, 'أدعية الصباح');
    expect(combined.category, 'الأذكار المشتركة');
    expect(combined.category, isNot('أدعية الصباح'));
    expect(combined.category, isNot('أدعية المساء'));
  });
}
