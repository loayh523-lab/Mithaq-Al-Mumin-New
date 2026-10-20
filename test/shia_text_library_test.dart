import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_al_mumin/features/shia_text_library_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Arabic dua and ziyara library has readable content and distinct categories', () async {
    final data = await ShiaTextData.load();

    expect(data.entries, isNotEmpty);
    expect(
      data.entries.any((entry) => entry.category == 'الزيارات'),
      isTrue,
    );
    expect(
      data.entries.any((entry) => entry.category == 'أدعية الصباح'),
      isTrue,
    );
    expect(
      data.entries.any((entry) => entry.category == 'أدعية المساء'),
      isTrue,
    );
    expect(
      data.entries.any((entry) => entry.category == 'الأعمال اليومية والمناسبات'),
      isTrue,
    );
    expect(
      data.entries.any((entry) => entry.category == 'الأعمال الشهرية والمناسبات'),
      isTrue,
    );

    // Mafatih al-Jinan is intentionally not merged into the library while its
    // complete Arabic edition is being prepared for the user's review.
    expect(
      data.entries.any((entry) => entry.sourceLabel.startsWith('مفاتيح الجنان،')),
      isFalse,
      reason: 'Do not silently merge Mafatih content before the Arabic source is reviewed.',
    );
    expect(
      data.entries.every((entry) => entry.arabicText.trim().isNotEmpty),
      isTrue,
      reason: 'Every library entry must have readable Arabic text.',
    );

    for (final entry in data.entries) {
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
}
