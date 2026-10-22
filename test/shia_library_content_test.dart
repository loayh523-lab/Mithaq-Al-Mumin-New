import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_al_mumin/features/shia_text_library_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Curated offline Arabic supplication library', () {
    test('contains exactly 110 complete texts in the five agreed sections', () async {
      final data = await ShiaTextData.load();
      expect(data.entries, hasLength(110));

      const expectedCounts = <String, int>{
        'الصحيفة السجادية والمناجيات': 76,
        'الأدعية والأذكار اليومية': 11,
        'الأدعية العامة وأدعية الفرج وصاحب الزمان': 10,
        'الأعمال والمناسبات': 7,
        'الزيارات الشريفة': 6,
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
  });
}
