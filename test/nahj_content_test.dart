import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_al_mumin/features/faith_library_pages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('offline Nahj data includes sermons, letters, and wisdoms', () async {
    final entries = await NahjData.load();

    expect(entries.length, greaterThanOrEqualTo(500));
    expect(entries.any((entry) => entry.category == 1), isTrue);
    expect(entries.any((entry) => entry.category == 2), isTrue);
    expect(entries.any((entry) => entry.category == 3), isTrue);
    expect(entries.every((entry) => entry.text.trim().isNotEmpty), isTrue);
  });
}
