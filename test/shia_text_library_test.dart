import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_al_mumin/features/shia_text_library_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Mafatih content is merged into the Arabic library, not a separate category', () async {
    final data = await ShiaTextData.load();

    expect(data.entries, isNotEmpty);
    final mafatihEntries = data.entries
        .where((entry) => entry.sourceLabel.startsWith('مفاتيح الجنان،'))
        .toList(growable: false);
    expect(
      mafatihEntries,
      isNotEmpty,
      reason: 'Imported texts should retain a human-readable citation to the book and actual headings.',
    );
    expect(
      mafatihEntries.every((entry) =>
          entry.sourceLabel.contains('القسم:') &&
          !entry.sourceLabel.contains('باب: الباب')),
      isTrue,
      reason: 'Mafatih citations should show the actual chapter heading without repeating the word باب.',
    );
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
    expect(
      data.entries.any((entry) => entry.category == 'مفاتيح الجنان'),
      isFalse,
      reason: 'The book title is a source citation, never a library category.',
    );
    expect(
      data.entries.where((entry) => entry.sourceLabel.startsWith('مفاتيح الجنان،'))
          .every((entry) => entry.arabicText.trim().isNotEmpty),
      isTrue,
      reason: 'Imported entries must not create blank reader pages.',
    );
    expect(
      data.entries.every((entry) => !RegExp(r'[A-Za-zپچژگ]').hasMatch(entry.displayTitle)),
      isTrue,
      reason: 'Visible entry titles must be Arabic, never English transliteration or Persian-script headings.',
    );
  });
}
