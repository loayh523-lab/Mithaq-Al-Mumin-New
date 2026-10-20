import 'dart:math' as math;

import 'package:geomag/geomag.dart';

const double _kaabaLatitude = 21.4225;
const double _kaabaLongitude = 39.8262;

/// Great-circle initial bearing from a location toward the Kaaba, measured
/// clockwise from geographic (true) north.
double qiblaBearingDegrees({
  required double latitude,
  required double longitude,
}) {
  const radians = math.pi / 180;
  final lat1 = latitude * radians;
  final lat2 = _kaabaLatitude * radians;
  final deltaLongitude = (_kaabaLongitude - longitude) * radians;
  final y = math.sin(deltaLongitude) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(deltaLongitude);
  return (math.atan2(y, x) / radians + 360) % 360;
}

/// WMM2025 magnetic declination in degrees. Positive values indicate magnetic
/// north is east of geographic north. Calculated locally; no network required.
double magneticDeclinationDegrees({
  required double latitude,
  required double longitude,
  DateTime? date,
}) {
  final result = GeoMag().calculate(
    latitude,
    longitude,
    0,
    date ?? DateTime.now(),
  );
  return result.dec;
}

/// Convert a true-north bearing into the equivalent bearing relative to
/// magnetic north, matching the reference frame of the phone's compass.
double magneticQiblaBearingDegrees({
  required double trueBearing,
  required double declinationDegrees,
}) {
  return ((trueBearing - declinationDegrees) % 360 + 360) % 360;
}
