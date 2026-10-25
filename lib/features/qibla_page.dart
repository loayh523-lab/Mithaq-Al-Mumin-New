import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../services/prayer_locations.dart';
import '../services/qibla_calculation.dart';

const _qiblaGold = Color(0xFFD9B66D);
const _qiblaGreen = Color(0xFF367B58);

/// Live compass direction. The numeric bearing remains available if the
/// device has no compass sensor or the sensor has not initialized yet.
class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key, this.onLocationChanged, this.compassEvents});

  final Future<void> Function()? onLocationChanged;

  @visibleForTesting
  final Stream<CompassEvent?>? compassEvents;

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  PrayerCity _city = PrayerLocations.cities.first;
  bool _gpsBusy = false;
  double? _gpsAccuracy;
  double? _declinationDegrees;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    _loadCity();
  }

  Future<void> _loadCity() async {
    try {
      final selected = await PrayerLocations.load();
      if (!mounted) return;
      double? accuracy;
      if (selected.id == 'current_location') {
        accuracy = await PrayerLocations.currentLocationAccuracy();
      }
      if (!mounted) return;
      setState(() {
        _city = selected;
        _gpsAccuracy = accuracy;
        _declinationDegrees = _tryDeclination(selected);
      });
    } catch (_) {
      // Keep the default city and the numeric Qibla bearing available.
    }
  }

  Future<void> _refreshLocation() async {
    if (_gpsBusy) return;
    setState(() {
      _gpsBusy = true;
      _locationMessage = null;
    });
    try {
      final precise = await PrayerLocations.acquirePreciseLocation();
      if (!mounted) return;
      if (precise == null) {
        setState(() {
          _locationMessage =
              'ما قدرنا نحدد الموقع بدقة. فعّل الموقع واسمح للتطبيق باستخدامه، أو اعتمد إحداثيات المدينة المختارة.';
        });
      } else {
        final accuracy = await PrayerLocations.currentLocationAccuracy();
        if (!mounted) return;
        setState(() {
          _city = precise;
          _gpsAccuracy = accuracy;
          _declinationDegrees = _tryDeclination(precise);
          _locationMessage = accuracy == null
              ? 'تم تحديث الموقع من GPS.'
              : 'تم تحديث الموقع؛ دقة GPS المعلنة نحو ${accuracy.round()} متر.';
        });
        await widget.onLocationChanged?.call();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _locationMessage = 'تعذّر تحديث الموقع حالياً. تحقق من صلاحيات الموقع وحاول مجدداً.');
      }
    } finally {
      if (mounted) setState(() => _gpsBusy = false);
    }
  }

  double? _tryDeclination(PrayerCity city) {
    try {
      final value = magneticDeclinationDegrees(
        latitude: city.latitude,
        longitude: city.longitude,
      );
      return value.isFinite ? value : null;
    } catch (_) {
      return null;
    }
  }

  double get _trueBearing => qiblaBearingDegrees(
        latitude: _city.latitude,
        longitude: _city.longitude,
      );

  double get _magneticBearing => magneticQiblaBearingDegrees(
        trueBearing: _trueBearing,
        declinationDegrees: _declinationDegrees ?? 0,
      );

  String get _declinationLabel {
    final value = _declinationDegrees;
    if (value == null) return 'تعذّر حساب تصحيح الشمال المغناطيسي؛ السهم يستخدم التصحيح الصفري مؤقتاً.';
    final direction = value >= 0 ? 'شرقاً' : 'غرباً';
    return 'تصحيح الشمال المغناطيسي: ${value.abs().toStringAsFixed(1)}° $direction';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final surface = theme.colorScheme.surface;
    final compassSize = (MediaQuery.sizeOf(context).width - 72)
        .clamp(200.0, 270.0)
        .toDouble();
    return Scaffold(
      appBar: AppBar(
        title: const Text('اتجاه القبلة'),
        actions: [
          IconButton(
            tooltip: 'تحديث الموقع الدقيق',
            onPressed: _gpsBusy ? null : _refreshLocation,
            icon: _gpsBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: StreamBuilder<CompassEvent?>(
        stream: widget.compassEvents ?? FlutterCompass.events,
        builder: (context, snapshot) {
          final heading = snapshot.data?.heading;
          final sensorUnavailable = heading == null || !heading.isFinite;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: theme.brightness == Brightness.dark
                        ? const [Color(0xFF19392B), Color(0xFF111B16)]
                        : const [Color(0xFFE7F2E9), Color(0xFFF8F5EB)],
                  ),
                  border: Border.all(color: _qiblaGold.withValues(alpha: .28)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.mosque_rounded, size: 34, color: _qiblaGold),
                    const SizedBox(height: 8),
                    Text(
                      'اتجاه الكعبة المشرفة',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_trueBearing.round()}° من الشمال الجغرافي',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _qiblaGold),
                    ),
                    const SizedBox(height: 5),
                    Text(_declinationLabel, textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12, height: 1.5)),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: compassSize,
                      height: compassSize,
                      child: sensorUnavailable
                          ? _staticCompass(context, _magneticBearing)
                          : Transform.rotate(
                              angle: -heading * math.pi / 180,
                              child: _compassFace(context, _magneticBearing),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      sensorUnavailable
                          ? 'قراءة الحساس غير متاحة؛ الاتجاه الرقمي أعلاه محسوب من موقعك.'
                          : 'اتجاه الهاتف: ${heading.round()}° من الشمال المغناطيسي',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Card(
                elevation: 0,
                color: surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: _qiblaGold),
                          const SizedBox(width: 8),
                          Expanded(child: Text('الموقع المعتمد', style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface))),
                          TextButton.icon(
                            onPressed: _gpsBusy ? null : _refreshLocation,
                            icon: const Icon(Icons.gps_fixed_rounded, size: 18),
                            label: const Text('تحديث'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_city.name} · ${_city.id == 'current_location' ? 'موقع الجهاز' : 'إحداثيات المدينة المختارة'}',
                        style: TextStyle(color: muted, height: 1.5),
                      ),
                      if (_gpsAccuracy != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('دقة GPS المعلنة نحو ${_gpsAccuracy!.round()} متر', style: TextStyle(color: muted, fontSize: 12)),
                        ),
                      if (_locationMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(_locationMessage!, style: const TextStyle(color: _qiblaGreen, height: 1.5)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'لتحسين الدقة: أبعد الهاتف عن المغناطيس والأغطية المغناطيسية والمعادن، وحرّكه بهدوء على شكل رقم 8. اتجاه السهم يعتمد على حساس الهاتف ومعايرته؛ إذا لم يتوفر الحساس، استخدم الدرجة الرقمية ولا تعتمد على السهم.',
                style: TextStyle(color: muted, fontSize: 12, height: 1.65),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _staticCompass(BuildContext context, double bearing) {
    return _compassFace(context, bearing);
  }

  Widget _compassFace(BuildContext context, double bearing) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _qiblaGold.withValues(alpha: .55), width: 2),
          ),
        ),
        for (var degree = 0; degree < 360; degree += 30)
          Transform.rotate(
            angle: degree * math.pi / 180,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 7),
                width: degree % 90 == 0 ? 3 : 1.5,
                height: degree % 90 == 0 ? 15 : 8,
                color: degree % 90 == 0 ? _qiblaGold : muted.withValues(alpha: .45),
              ),
            ),
          ),
        Positioned(top: 24, child: Text('شمال', style: TextStyle(color: muted, fontWeight: FontWeight.bold, fontSize: 12))),
        Positioned(bottom: 24, child: Text('جنوب', style: TextStyle(color: muted, fontSize: 12))),
        Positioned(left: 18, child: Text('غرب', style: TextStyle(color: muted, fontSize: 12))),
        Positioned(right: 18, child: Text('شرق', style: TextStyle(color: muted, fontSize: 12))),
        Transform.rotate(
          angle: bearing * math.pi / 180,
          child: const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 44),
              child: Icon(Icons.navigation_rounded, size: 92, color: _qiblaGold),
            ),
          ),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(color: theme.colorScheme.surface, shape: BoxShape.circle, border: Border.all(color: _qiblaGold, width: 2)),
        ),
      ],
    );
  }
}
