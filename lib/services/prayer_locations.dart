import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerAdministrativeDivision {
  const PrayerAdministrativeDivision({
    required this.id,
    required this.level,
    required this.name,
    required this.parentId,
    required this.governorateId,
    required this.governorateName,
    required this.districtId,
    required this.districtName,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  /// 1 = governorate, 2 = district (qadha), 3 = sub-district (nahia).
  final int level;
  final String name;
  final String? parentId;
  final String governorateId;
  final String governorateName;
  final String? districtId;
  final String? districtName;
  final double latitude;
  final double longitude;

  factory PrayerAdministrativeDivision.fromJson(Map<String, dynamic> json) {
    return PrayerAdministrativeDivision(
      id: json['id'] as String,
      level: json['level'] as int,
      name: json['name'] as String,
      parentId: json['parentId'] as String?,
      governorateId: json['governorateId'] as String,
      governorateName: json['governorateName'] as String,
      districtId: json['districtId'] as String?,
      districtName: json['districtName'] as String?,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
    );
  }
}

class PrayerCity {
  const PrayerCity({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.governorateId,
    this.governorateName,
    this.districtId,
    this.districtName,
    this.subdistrictId,
    this.subdistrictName,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? governorateId;
  final String? governorateName;
  final String? districtId;
  final String? districtName;
  final String? subdistrictId;
  final String? subdistrictName;

  bool get isCurrentLocation => id == 'current_location';

  String get administrativeLabel {
    final parts = <String>[];
    if (subdistrictName != null && subdistrictName!.isNotEmpty) {
      parts.add('الناحية: $subdistrictName');
    }
    if (districtName != null &&
        districtName!.isNotEmpty &&
        districtName != subdistrictName) {
      parts.add('القضاء: $districtName');
    }
    if (governorateName != null && governorateName!.isNotEmpty) {
      parts.add('المحافظة: $governorateName');
    }
    return parts.join(' • ');
  }
}

class PrayerLocations {
  static const cities = <PrayerCity>[
    PrayerCity(id: 'qalat_sukar', name: 'قلعة سكر', latitude: 31.85, longitude: 46.07),
    PrayerCity(id: 'nasiriyah', name: 'الناصرية', latitude: 31.05, longitude: 46.26),
    PrayerCity(id: 'baghdad', name: 'بغداد', latitude: 33.3152, longitude: 44.3661),
    PrayerCity(id: 'najaf', name: 'النجف الأشرف', latitude: 32.025, longitude: 44.335),
    PrayerCity(id: 'karbala', name: 'كربلاء المقدسة', latitude: 32.616, longitude: 44.025),
    PrayerCity(id: 'basra', name: 'البصرة', latitude: 30.5085, longitude: 47.7804),
    PrayerCity(id: 'kufa', name: 'الكوفة', latitude: 32.0303, longitude: 44.4036),
    PrayerCity(id: 'amarah', name: 'العمارة', latitude: 31.8359, longitude: 47.1448),
  ];

  static const administrativeAsset =
      'assets/locations/iraq_administrative_divisions.json';
  static Future<List<PrayerAdministrativeDivision>>? _divisionsFuture;

  static Future<List<PrayerAdministrativeDivision>>
      administrativeDivisions() async {
    final existing = _divisionsFuture;
    if (existing != null) return existing;

    final future = _readAdministrativeDivisions();
    _divisionsFuture = future;
    try {
      return await future;
    } catch (_) {
      _divisionsFuture = null;
      rethrow;
    }
  }

  static Future<List<PrayerAdministrativeDivision>>
      _readAdministrativeDivisions() async {
    final raw = await rootBundle.loadString(administrativeAsset);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final records = (decoded['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(PrayerAdministrativeDivision.fromJson)
        .toList(growable: false);

    final ids = records.map((record) => record.id).toSet();
    if (ids.length != records.length ||
        records.any((record) =>
            record.name.trim().isEmpty ||
            !record.latitude.isFinite ||
            !record.longitude.isFinite ||
            record.latitude < -90 ||
            record.latitude > 90 ||
            record.longitude < -180 ||
            record.longitude > 180)) {
      throw const FormatException(
        'Invalid or duplicate Iraq administrative location records.',
      );
    }
    return records;
  }

  static List<PrayerAdministrativeDivision> governoratesFrom(
    List<PrayerAdministrativeDivision> divisions,
  ) =>
      divisions.where((item) => item.level == 1).toList(growable: false);

  static List<PrayerAdministrativeDivision> districtsFrom(
    List<PrayerAdministrativeDivision> divisions,
    String governorateId,
  ) =>
      divisions
          .where((item) =>
              item.level == 2 && item.governorateId == governorateId)
          .toList(growable: false);

  static List<PrayerAdministrativeDivision> subdistrictsFrom(
    List<PrayerAdministrativeDivision> divisions,
    String districtId,
  ) =>
      divisions
          .where((item) => item.level == 3 && item.districtId == districtId)
          .toList(growable: false);

  static PrayerAdministrativeDivision? divisionById(
    List<PrayerAdministrativeDivision> divisions,
    String? id,
  ) {
    if (id == null) return null;
    for (final item in divisions) {
      if (item.id == id) return item;
    }
    return null;
  }

  static PrayerAdministrativeDivision? nearestDivision(
    List<PrayerAdministrativeDivision> divisions, {
    required double latitude,
    required double longitude,
    int level = 3,
  }) {
    final candidates = divisions.where((item) => item.level == level);
    PrayerAdministrativeDivision? nearest;
    var minimumDistance = double.infinity;
    final longitudeScale = math.cos(latitude * math.pi / 180);

    for (final item in candidates) {
      final latitudeDelta = item.latitude - latitude;
      final longitudeDelta = (item.longitude - longitude) * longitudeScale;
      final distance = latitudeDelta * latitudeDelta +
          longitudeDelta * longitudeDelta;
      if (distance < minimumDistance) {
        minimumDistance = distance;
        nearest = item;
      }
    }
    return nearest;
  }

  static PrayerCity cityForDivision(PrayerAdministrativeDivision division) =>
      PrayerCity(
        id: division.id,
        name: division.name,
        latitude: division.latitude,
        longitude: division.longitude,
        governorateId: division.governorateId,
        governorateName: division.governorateName,
        districtId: division.districtId,
        districtName: division.districtName,
        subdistrictId: division.level == 3 ? division.id : null,
        subdistrictName: division.level == 3 ? division.name : null,
      );

  static PrayerCity byId(String? id) {
    for (final city in cities) {
      if (city.id == id) return city;
    }
    return cities.first;
  }

  /// Request and store a fresh GPS fix. Returns null when access or accuracy
  /// is insufficient, allowing the previous city to remain as a fallback.
  static Future<PrayerCity?> acquirePreciseLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 25),
        ),
      );
      if (!position.latitude.isFinite ||
          !position.longitude.isFinite ||
          position.accuracy.isNaN ||
          position.accuracy > 250) {
        return null;
      }
      await saveCurrentLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );
      return PrayerCity(
        id: 'current_location',
        name: 'موقعي الحالي',
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<double?> currentLocationAccuracy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('prayer_location_accuracy_meters');
  }

  static Future<PrayerCity> load() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble('prayer_latitude');
    final longitude = prefs.getDouble('prayer_longitude');
    if (latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180) {
      return PrayerCity(
        id: 'current_location',
        name: prefs.getString('prayer_location_name') ?? 'موقعي الحالي',
        latitude: latitude,
        longitude: longitude,
      );
    }

    final selectedPlaceId = prefs.getString('prayer_place_id');
    if (selectedPlaceId != null) {
      try {
        final divisions = await administrativeDivisions();
        final division = divisionById(divisions, selectedPlaceId);
        if (division != null) return cityForDivision(division);
      } catch (_) {
        // A missing asset must not prevent the app from opening.
      }
    }

    // Keep settings saved by earlier app versions working until the user
    // chooses a location from the fuller governorate/district picker.
    return byId(prefs.getString('prayer_city'));
  }

  static Future<void> savePlace(PrayerAdministrativeDivision division) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('prayer_latitude');
    await prefs.remove('prayer_longitude');
    await prefs.remove('prayer_location_name');
    await prefs.remove('prayer_location_accuracy_meters');
    await prefs.remove('prayer_city');
    await prefs.setString('prayer_place_id', division.id);
  }

  static Future<void> save(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('prayer_latitude');
    await prefs.remove('prayer_longitude');
    await prefs.remove('prayer_location_name');
    await prefs.remove('prayer_location_accuracy_meters');
    await prefs.remove('prayer_place_id');
    await prefs.setString('prayer_city', byId(id).id);
  }

  static Future<void> saveCurrentLocation({
    required double latitude,
    required double longitude,
    double? accuracyMeters,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('prayer_latitude', latitude);
    await prefs.setDouble('prayer_longitude', longitude);
    await prefs.setString('prayer_location_name', 'موقعي الحالي');
    if (accuracyMeters != null) {
      await prefs.setDouble('prayer_location_accuracy_meters', accuracyMeters);
    }
  }
}
