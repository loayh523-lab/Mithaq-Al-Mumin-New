import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_al_mumin/features/shia_text_library_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Curated offline Arabic supplication library', () {
    test('contains exactly 110 complete texts in the five curated sections', () async {
      final data = await ShiaTextData.loadCore();
      expect(data.entries, hasLength(110));

      const expectedCounts = <String, int>{
        'الأدعية والأذكار اليومية': 25,
        'التعقيبات بعد الصلاة': 5,
        'الأدعية العامة وأدعية الفرج وصاحب الزمان': 35,
        'الأعمال والمناسبات': 20,
        'الزيارات الشريفة': 25,
      };
      final counts = <String, int>{};
      final slugs = <String>{};
      final completeTexts = <String>{};

      String normalize(String value) => value
          .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
          .replaceAll(RegExp('[أإآٱ]'), 'ا')
          .replaceAll('ى', 'ي')
          .replaceAll(RegExp(r'[^\u0600-\u06FF0-9]'), '');

      for (final entry in data.entries) {
        expect(entry.slug, isNotEmpty);
        expect(slugs.add(entry.slug), isTrue, reason: 'Duplicate slug: \${entry.slug}');
        expect(entry.title, isNotEmpty);
        expect(entry.sourceReference, isNotEmpty, reason: 'Missing source reference: \${entry.slug}');
        expect(entry.sourceUrl, startsWith('https://github.com/KazTronics/'));
        expect(entry.lines, isNotEmpty, reason: 'Missing full text: \${entry.slug}');
        expect(entry.categoryOverride, isNotNull);
        counts.update(entry.category, (count) => count + 1, ifAbsent: () => 1);

        for (final line in entry.lines) {
          expect(line.kind, 'arabic');
          expect(line.text, isNotEmpty);
          expect(
            RegExp(r'[\u067E\u0686\u0698\u06AF\u06A9\u06CCA-Za-z]').hasMatch(line.text),
            isFalse,
            reason: 'Persian or Latin letters in \${entry.slug}',
          );
        }
        final key = normalize(entry.arabicText);
        expect(key, isNotEmpty);
        expect(completeTexts.add(key), isTrue, reason: 'Duplicate text: \${entry.slug}');
      }

      expect(counts, expectedCounts);
      expect(slugs, hasLength(110));
      expect(completeTexts, hasLength(110));
    });
    test('taqibat after prayer have a distinct section and meaningful content-based titles', () async {
      final data = await ShiaTextData.loadCore();
      final taqibat = data.entries.where((entry) => entry.slug.startsWith('taqib-after-salaat-')).toList();
      expect(taqibat, hasLength(5));
      expect(taqibat.every((entry) => entry.category == 'التعقيبات بعد الصلاة'), isTrue);
      expect(taqibat.map((entry) => entry.displayTitle).toSet(), hasLength(5));
      expect(taqibat.every((entry) => !['(1)', '(2)', '(3)', '(4)', '(5)'].any((number) => entry.displayTitle.contains(number)), isTrue);
      expect(taqibat.every((entry) => entry.displayTitle != entry.title), isTrue);
    });

    test('combined library contains the curated collection and Sahifa without duplicate identifiers', () async {
      final data = await ShiaTextData.load();
      expect(data.entries, hasLength(186));
      expect(
        data.entries.where((entry) => entry.category == 'الصحيفة السجادية والمناجيات'),
        hasLength(76),
      );
      expect(
        data.entries.where((entry) => entry.category != 'الصحيفة السجادية والمناجيات'),
        hasLength(110),
      );
      expect(data.entries.map((entry) => entry.slug).toSet(), hasLength(186));
    });

    test('preserves Sahifa and Munajat separately without counting them among the 110', () async {
      final data = await ShiaTextData.loadSahifa();
      expect(data.entries, hasLength(76));
      expect(
        data.entries.every((entry) => entry.category == 'الصحيفة السجادية والمناجيات'),
        isTrue,
      );
      expect(data.entries.map((entry) => entry.slug).toSet(), hasLength(76));
    });

  });
}
