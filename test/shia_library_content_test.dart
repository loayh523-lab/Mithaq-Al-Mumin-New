import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_al_mumin/features/shia_text_library_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Curated offline Arabic supplication library', () {
    test('contains 250 complete unique texts mapped into the six public sections', () async {
      final data = await ShiaTextData.loadCore();
      expect(data.entries, hasLength(250));

      const expectedCounts = <String, int>{
        'الورد اليومي والتعقيبات': 32,
        'الأدعية الكبرى والمناجاة الشريفة': 25,
        'أدعية المناسبات والشهور العبادية': 50,
        'الصحيفة السجادية المباركة (نفحات مختارة)': 35,
        'أدعية الحوائج، التحصينات والرزق': 50,
        'الزيارات الشريفة والمقامات المقدسة': 58,
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
        expect(slugs.add(entry.slug), isTrue, reason: 'Duplicate slug: ' + entry.slug);
        expect(entry.title, isNotEmpty);
        expect(entry.sourceReference, isNotEmpty, reason: 'Missing source reference: ' + entry.slug);
        expect(entry.sourceUrl, startsWith('https://github.com/KazTronics/'));
        expect(entry.lines, isNotEmpty, reason: 'Missing full text: ' + entry.slug);
        expect(entry.categoryOverride, isNotNull);
        counts.update(entry.category, (count) => count + 1, ifAbsent: () => 1);

        for (final line in entry.lines) {
          expect(line.kind, 'arabic');
          expect(line.text, isNotEmpty);
          expect(
            RegExp(r'[\u067E\u0686\u0698\u06AF\u06A9\u06CCA-Za-z]').hasMatch(line.text),
            isFalse,
            reason: 'Persian or Latin letters in ' + entry.slug,
          );
        }
        final key = normalize(entry.arabicText);
        expect(key, isNotEmpty);
        expect(completeTexts.add(key), isTrue, reason: 'Duplicate text: ' + entry.slug);
      }

      expect(counts, expectedCounts);
      expect(slugs, hasLength(250));
      expect(completeTexts, hasLength(250));
    });

    test('five prayer taqibat have distinct meaningful titles', () async {
      final data = await ShiaTextData.loadCore();
      final taqibat = data.entries
          .where((entry) => entry.title.startsWith('تعقيب الصلاة'))
          .toList();
      expect(taqibat, hasLength(5));
      expect(taqibat.every((entry) => entry.category == 'الورد اليومي والتعقيبات'), isTrue);
      expect(taqibat.map((entry) => entry.displayTitle).toSet(), hasLength(5));
      expect(taqibat.every((entry) => entry.displayTitle == entry.title), isTrue);
    });

    test('the public library exposes all 250 texts once', () async {
      final data = await ShiaTextData.load();
      expect(data.entries, hasLength(250));
      expect(data.entries.map((entry) => entry.slug).toSet(), hasLength(250));
      expect(data.entries.where((entry) => entry.isSahifa), hasLength(35));
    });

    test('the Sahifa view exposes the 20 selected duas and 15 Munajat only', () async {
      final data = await ShiaTextData.loadSahifa();
      expect(data.entries, hasLength(35));
      expect(data.entries.where((entry) => entry.type == 'sahifa'), hasLength(20));
      expect(data.entries.where((entry) => entry.type == 'munajat'), hasLength(15));
      expect(data.entries.every((entry) =>
          entry.category == 'الصحيفة السجادية المباركة (نفحات مختارة)'), isTrue);
      expect(data.entries.map((entry) => entry.slug).toSet(), hasLength(35));
    });
  });
}
