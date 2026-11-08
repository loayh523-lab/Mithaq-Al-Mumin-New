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
        expect(slugs.add(entry.slug), isTrue, reason: 'Duplicate slug: ${entry.slug}');
        expect(entry.title, isNotEmpty);
        expect(entry.sourceReference, isNotEmpty, reason: 'Missing source reference: ${entry.slug}');
        final sourceUri = Uri.parse(entry.sourceUrl);
        expect(sourceUri.scheme, 'https');
        expect(sourceUri.host, isNotEmpty);
        expect(entry.lines, isNotEmpty, reason: 'Missing full text: ${entry.slug}');
        expect(entry.categoryOverride, isNotNull);
        counts.update(entry.category, (count) => count + 1, ifAbsent: () => 1);

        for (final line in entry.lines) {
          expect(line.kind, 'arabic');
          expect(line.text, isNotEmpty);
          expect(
            RegExp(r'[\u067E\u0686\u0698\u06AF\u06A9\u06CCA-Za-z]').hasMatch(line.text),
            isFalse,
            reason: 'Persian or Latin letters in ${entry.slug}',
          );
        }
        final key = normalize(entry.arabicText);
        expect(key, isNotEmpty);
        expect(completeTexts.add(key), isTrue, reason: 'Duplicate text: ${entry.slug}');
      }

      expect(counts, expectedCounts);
      expect(slugs, hasLength(250));
      expect(completeTexts, hasLength(250));
    });

    test('Quranic texts have direct verse references and accurate classification', () async {
      final data = await ShiaTextData.loadCore();
      final bySlug = {for (final entry in data.entries) entry.slug: entry};

      const expectedReferences = <String, String>{
        'hajat-137': 'سورة البقرة، الآيات 255–257 (2:255–257)',
        'hajat-287': 'سورة آل عمران، الآيتان 18–19 (3:18–19)',
        'hajat-288': 'سورة آل عمران، الآيتان 26–27 (3:26–27)',
        'hajat-317': 'سورة الأنبياء، الآيتان 87–88 (21:87–88)',
        'hajat-318': 'سورة الأنعام، الآية 59 (6:59)',
        'major-292': 'سورة آل عمران، الآية 147 (3:147)',
        'major-293': 'سورة آل عمران، الآية 8 (3:8)',
      };

      for (final item in expectedReferences.entries) {
        final entry = bySlug[item.key];
        expect(entry, isNotNull, reason: 'Missing Quran item: ${item.key}');
        expect(entry!.type, 'quran', reason: 'Incorrect type: ${item.key}');
        expect(entry.sourceReference, contains(item.value),
            reason: 'Missing direct Quran reference: ${item.key}');
        expect(entry.sourceReference, isNot(contains('لا يذكر السجل اسم الكتاب التراثي الأصلي')));
      }

      expect(bySlug['hajat-137']!.title, 'آية الكرسي والآيتان بعدها');
      final quranEntries = data.entries.where((entry) => entry.type == 'quran');
      expect(quranEntries, hasLength(47));
      expect(
        quranEntries.every((entry) =>
            !entry.sourceReference.contains('لا يذكر السجل اسم الكتاب التراثي الأصلي')),
        isTrue,
      );
    });

    test('daily supplications keep their verified historical source references', () async {
      final data = await ShiaTextData.loadCore();
      final bySlug = {for (final entry in data.entries) entry.slug: entry};

      const expectedSources = <String, String>{
        'daily-283': 'جنة الأمان الواقية وجنة الإيمان الباقية',
        'daily-284': 'مفاتيح الجنان',
        'daily-285': 'مصباح الكفعمي',
        'daily-286': 'مدارك العروة',
        'daily-296': 'من لا يحضره الفقيه',
        'daily-380': 'من لا يحضره الفقيه',
        'daily-396': 'الأمالي',
        'daily-397': 'وسائل الشيعة',
      };

      for (final item in expectedSources.entries) {
        final entry = bySlug[item.key];
        expect(entry, isNotNull, reason: 'Missing daily entry: ${item.key}');
        expect(entry!.sourceReference, contains(item.value),
            reason: 'Missing historical source: ${item.key}');
        expect(
          entry.sourceReference,
          isNot(contains('لا يذكر السجل اسم الكتاب التراثي الأصلي')),
          reason: 'Unresolved-source marker remains: ${item.key}',
        );
      }
    });

    test('major supplications retain their located historical sources', () async {
      final data = await ShiaTextData.loadCore();
      final bySlug = {for (final entry in data.entries) entry.slug: entry};

      const expectedSources = <String, String>{
        'major-17': 'مفاتيح الجنان',
        'major-107': 'مصباح الزائر',
        'major-358': 'الكافي',
        'major-359': 'مهج الدعوات',
        'major-362': 'مصباح المتهجد',
        'major-405': 'مصباح المتهجد',
        'major-408': 'مكارم الأخلاق',
        'major-409': 'مستدرك الوسائل',
        'major-410': 'البلد الأمين',
        'major-415': 'مفاتيح الجنان',
      };

      for (final item in expectedSources.entries) {
        final entry = bySlug[item.key];
        expect(entry, isNotNull, reason: 'Missing major entry: ${item.key}');
        expect(entry!.sourceReference, contains(item.value),
            reason: 'Missing historical source: ${item.key}');
        expect(
          entry.sourceReference,
          isNot(contains('لا يذكر السجل اسم الكتاب التراثي الأصلي')),
          reason: 'Unresolved-source marker remains: ${item.key}',
        );
      }
      expect(bySlug['major-415']!.type, 'occasion');
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

    test('the public library exposes 230 approved texts once', () async {
      final data = await ShiaTextData.load();
      expect(data.entries, hasLength(230));
      expect(data.entries.map((entry) => entry.slug).toSet(), hasLength(230));
      expect(data.entries.where((entry) => entry.slug.startsWith('selected-sahifa-')), isEmpty);
      expect(data.entries.where((entry) => entry.type == 'munajat'), hasLength(15));
      expect(data.entries.where((entry) => entry.isSahifa), hasLength(15));
    });

    test('the Sahifa view publishes only the 15 Munajat while selected duas await approval', () async {
      final data = await ShiaTextData.loadSahifa();
      expect(data.entries, hasLength(15));
      expect(data.entries.where((entry) => entry.type == 'sahifa'), isEmpty);
      expect(data.entries.where((entry) => entry.type == 'munajat'), hasLength(15));
      expect(data.entries.every((entry) =>
          entry.category == 'الصحيفة السجادية المباركة (نفحات مختارة)'), isTrue);
      expect(data.entries.map((entry) => entry.slug).toSet(), hasLength(15));
    });
  });
}
