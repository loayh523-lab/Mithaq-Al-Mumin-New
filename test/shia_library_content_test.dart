import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_al_mumin/features/shia_text_library_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Curated offline Arabic supplication library', () {
    test('contains exactly 110 complete texts mapped into the public taxonomy', () async {
      final data = await ShiaTextData.loadCore();
      expect(data.entries, hasLength(110));

      const expectedCounts = <String, int>{
        'الورد اليومي والتعقيبات': 30,
        'الأدعية الكبرى والمناجاة الشريفة': 35,
        'أدعية المناسبات والشهور العبادية': 20,
        'الزيارات الشريفة والمقامات المقدسة': 25,
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
      expect(taqibat.every((entry) => entry.category == 'الورد اليومي والتعقيبات'), isTrue);
      expect(taqibat.map((entry) => entry.displayTitle).toSet(), hasLength(5));
      expect(taqibat.every((entry) => !['(1)', '(2)', '(3)', '(4)', '(5)'].any((number) => entry.displayTitle.contains(number))), isTrue);
      expect(taqibat.every((entry) => entry.displayTitle != entry.title), isTrue);
    });

    test('the public library exposes only the 110 curated texts', () async {
      final data = await ShiaTextData.load();
      expect(data.entries, hasLength(110));
      expect(data.entries.map((entry) => entry.slug).toSet(), hasLength(110));
      expect(data.entries.every((entry) => !entry.isSahifa), isTrue);
    });

    test('does not publish the 76 source records as the approved 20-item selection', () async {
      final data = await ShiaTextData.loadSahifa();
      expect(data.entries, isEmpty);
      expect(data.sourceProject, isNotEmpty);
    });

  });
}
