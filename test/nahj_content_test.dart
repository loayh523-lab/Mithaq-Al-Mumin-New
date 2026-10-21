import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_al_mumin/features/faith_library_pages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('offline Nahj data includes the complete Arabic sermons, letters, and wisdoms', () async {
    final entries = await NahjData.load();

    expect(entries, hasLength(800));
    expect(entries.where((entry) => entry.category == 1), hasLength(241));
    expect(entries.where((entry) => entry.category == 2), hasLength(79));
    expect(entries.where((entry) => entry.category == 3), hasLength(480));
    expect(entries.every((entry) => entry.text.trim().isNotEmpty), isTrue);
    expect(
      entries.every(
        (entry) => !RegExp(r'[پچژگ]').hasMatch('${entry.title} ${entry.text}'),
      ),
      isTrue,
      reason: 'The bundled Arabic Nahj catalogue must not contain Persian-only letters.',
    );
  });
}
