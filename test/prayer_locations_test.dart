import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mithaq_al_mumin/features/settings_page.dart';
import 'package:mithaq_al_mumin/services/prayer_locations.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Iraq administrative data contains the full attributed hierarchy', () async {
    final divisions = await PrayerLocations.administrativeDivisions();
    final raw = await rootBundle.loadString(PrayerLocations.administrativeAsset);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final metadata = decoded['metadata'] as Map<String, dynamic>;

    expect(PrayerLocations.governoratesFrom(divisions), hasLength(19));
    expect(
      divisions.where((item) => item.level == 2),
      hasLength(101),
    );
    expect(
      divisions.where((item) => item.level == 3),
      hasLength(294),
    );
    expect(divisions.map((item) => item.id).toSet(), hasLength(414));
    expect(metadata['license'], 'CC-BY-4.0');
    expect(metadata['sourceCommit'], '098a1a49a16d5ab47fe63333ca9fa49970dc6e92');
    expect(metadata['attribution'], contains('Open Admin Data'));

    for (final division in divisions) {
      expect(division.name.trim(), isNotEmpty);
      expect(division.latitude, inInclusiveRange(29, 38));
      expect(division.longitude, inInclusiveRange(38, 49));
      expect(division.governorateName.trim(), isNotEmpty);
      if (division.level > 1) {
        final parent = PrayerLocations.divisionById(divisions, division.parentId);
        expect(
          parent,
          isNotNull,
          reason: 'Missing parent for ${division.id} (${division.name})',
        );
        expect(parent!.level, division.level - 1);
        expect(parent.governorateId, division.governorateId);
      }
    }
  });

  test('Halabja follows Law 7/2025 and the attached official unit codes', () async {
    final divisions = await PrayerLocations.administrativeDivisions();
    final halabja = PrayerLocations.divisionById(divisions, 'IQG19');
    final center = PrayerLocations.divisionById(divisions, 'IQG19Q01');
    expect(halabja, isNotNull);
    expect(halabja!.level, 1);
    expect(halabja.name, 'حلبجة');
    expect(halabja.officialCode, '16');
    expect(center, isNotNull);
    expect(center!.officialCode, '16011');
    expect(center.parentId, 'IQG19');

    final subdistricts = PrayerLocations.subdistrictsFrom(divisions, center.id);
    expect(subdistricts, hasLength(4));
    expect(
      subdistricts.map((item) => item.name).toSet(),
      <String>{'سيروان', 'خورمال', 'بيارة', 'بامو'},
    );
    expect(
      subdistricts.map((item) => item.officialCode).toSet(),
      <String>{'16012', '16013', '16014', '16015'},
    );
    expect(
      subdistricts.every((item) => item.governorateId == 'IQG19'),
      isTrue,
    );

    final raw = jsonDecode(
      await rootBundle.loadString(PrayerLocations.administrativeAsset),
    ) as Map<String, dynamic>;
    final metadata = raw['metadata'] as Map<String, dynamic>;
    final law = metadata['administrativeSupplement'] as Map<String, dynamic>;
    expect(law['lawNumber'], '7/2025');
    expect(law['gazetteIssue'], '4824');
    expect(law['officialGovernorateOrder'], 19);
    expect(divisions.where((item) => item.id.startsWith('IQG06Q05')).isEmpty, isTrue);
  });

  test('saved Halabja IDs from the former hierarchy migrate without falling back to another city', () async {
    const aliases = <String, String>{
      'IQG06Q05': 'IQG19Q01',
      'IQG06Q05N01': 'IQG19Q01N03',
      'IQG06Q05N02': 'IQG19Q01N02',
      'IQG06Q05N03': 'IQG19Q01',
      'IQG06Q05N04': 'IQG19Q01N01',
    };
    for (final entry in aliases.entries) {
      SharedPreferences.setMockInitialValues({
        'prayer_place_id': entry.key,
      });
      final restored = await PrayerLocations.load();
      expect(restored.id, entry.value, reason: 'Legacy ID ${entry.key}');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('prayer_place_id'), entry.value);
      expect(restored.governorateName, 'حلبجة');
    }
  });

  test('governorate, district and subdistrict filters retain parent relationships', () async {
    final divisions = await PrayerLocations.administrativeDivisions();
    final dhiQar = PrayerLocations.divisionById(divisions, 'IQG17');
    expect(dhiQar, isNotNull);
    expect(dhiQar!.name, 'ذي قار');

    final districts = PrayerLocations.districtsFrom(divisions, dhiQar.id);
    expect(districts, hasLength(5));
    expect(districts.every((item) => item.governorateId == dhiQar.id), isTrue);

    const rifaiId = 'IQG17Q02';
    final rifai = PrayerLocations.divisionById(divisions, rifaiId);
    expect(rifai?.name, 'الرفاعي');
    final subdistricts = PrayerLocations.subdistrictsFrom(divisions, rifaiId);
    expect(subdistricts, hasLength(4));

    final qalatSukar = subdistricts.singleWhere((item) => item.name == 'قلعة السكر');
    expect(qalatSukar.id, 'IQG17Q02N04');
    expect(qalatSukar.governorateName, 'ذي قار');
    expect(qalatSukar.districtName, 'الرفاعي');
    expect(qalatSukar.latitude, 31.836);
    expect(qalatSukar.longitude, 46.073);
  });

  test('a selected administrative place is restored for prayer calculations', () async {
    final divisions = await PrayerLocations.administrativeDivisions();
    final qalatSukar = PrayerLocations.divisionById(divisions, 'IQG17Q02N04');
    expect(qalatSukar, isNotNull);

    await PrayerLocations.savePlace(qalatSukar!);
    final restored = await PrayerLocations.load();

    expect(restored.id, qalatSukar.id);
    expect(restored.latitude, qalatSukar.latitude);
    expect(restored.longitude, qalatSukar.longitude);
    expect(restored.administrativeLabel, contains('قلعة السكر'));
    expect(restored.administrativeLabel, contains('الرفاعي'));
    expect(restored.administrativeLabel, contains('ذي قار'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('prayer_place_id'), qalatSukar.id);
    expect(prefs.getString('prayer_city'), isNull);
  });

  test('GPS coordinates take precedence over a previously saved administrative place', () async {
    final divisions = await PrayerLocations.administrativeDivisions();
    final place = PrayerLocations.divisionById(divisions, 'IQG17Q02N04')!;
    await PrayerLocations.savePlace(place);
    await PrayerLocations.saveCurrentLocation(
      latitude: 34.2,
      longitude: 44.1,
      accuracyMeters: 18,
    );

    final restored = await PrayerLocations.load();
    expect(restored.id, 'current_location');
    expect(restored.latitude, 34.2);
    expect(restored.longitude, 44.1);
  });

  testWidgets('settings cascade from governorate to subdistrict and save its coordinates', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: SettingsPage()),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('prayer-governorate-IQG17')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(3));
    expect(
      find.byKey(const ValueKey('prayer-governorate-IQG17')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('prayer-district-IQG17Q02')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey(
        'prayer-subdistrict-IQG17Q02-IQG17Q02N04',
      )),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('prayer-governorate-IQG17')),
    );
    await tester.tap(
      find.byKey(const ValueKey('prayer-governorate-IQG17')),
    );
    await tester.pumpAndSettle();
    expect(find.text('بابل'), findsOneWidget);
    await tester.tap(find.text('بابل').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('prayer-governorate-IQG07')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('prayer-district-none')),
    );
    await tester.tap(find.byKey(const ValueKey('prayer-district-none')));
    await tester.pumpAndSettle();
    expect(find.text('الحلة'), findsOneWidget);
    await tester.tap(find.text('الحلة').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('prayer-district-IQG07Q02')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey(
        'prayer-subdistrict-IQG07Q02-__district_center__',
      )),
    );
    await tester.tap(find.byKey(const ValueKey(
      'prayer-subdistrict-IQG07Q02-__district_center__',
    )));
    await tester.pumpAndSettle();
    expect(find.text('ابي غرق'), findsOneWidget);
    await tester.tap(find.text('ابي غرق').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey(
        'prayer-subdistrict-IQG07Q02-IQG07Q02N02',
      )),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('حفظ موقع الحساب'));
    await tester.tap(find.text('حفظ موقع الحساب'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('prayer_place_id'), 'IQG07Q02N02');
    final restored = await PrayerLocations.load();
    expect(restored.name, 'ابي غرق');
    expect(restored.governorateName, 'بابل');
    expect(restored.districtName, 'الحلة');
    expect(tester.takeException(), isNull);
  });
}
