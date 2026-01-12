import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class RouteMetrics {
  final double remainingDistanceMeters;
  final Duration remainingTime;
  final double progress;

  const RouteMetrics({
    required this.remainingDistanceMeters,
    required this.remainingTime,
    required this.progress,
  });

  factory RouteMetrics.initial() {
    return const RouteMetrics(
      remainingDistanceMeters: 0,
      remainingTime: Duration.zero,
      progress: 0,
    );
  }
}

class RouteProgressController {
  RouteProgressController({
    required MapLibreMapController mapController,
    required List<LatLng> routePoints,
    required ValueNotifier<RouteMetrics> metricsNotifier,
    required TickerProvider vsync,
    Duration totalDuration = const Duration(seconds: 96),
  })  : _mapController = mapController,
        _routePoints = routePoints,
        _metricsNotifier = metricsNotifier,
        _totalDuration = totalDuration,
        _ticker = vsync.createTicker(_onTick);

  final MapLibreMapController _mapController;
  final List<LatLng> _routePoints;
  final ValueNotifier<RouteMetrics> _metricsNotifier;
  final Duration _totalDuration;
  final Ticker _ticker;

  Line? _fullRouteLine;
  Line? _traveledLine;
  Duration _lastUpdate = Duration.zero;
  List<double> _cumulativeDistances = const [];

  static const Duration _updateInterval = Duration(milliseconds: 500);

  Future<void> initialize() async {
    if (_routePoints.isEmpty) {
      return;
    }
    _cumulativeDistances = _buildCumulativeDistances(_routePoints);
    _fullRouteLine = await _mapController.addLine(
      LineOptions(
        geometry: _routePoints,
        lineColor: '#7F8CFF',
        lineOpacity: 0.4,
        lineWidth: 6,
        lineJoin: 'round',
        lineCap: 'round',
      ),
    );
    _traveledLine = await _mapController.addLine(
      LineOptions(
        geometry: [_routePoints.first],
        lineColor: '#6AD9C1',
        lineOpacity: 0.9,
        lineWidth: 6,
        lineJoin: 'round',
        lineCap: 'round',
      ),
    );
    final totalDistance = _cumulativeDistances.isNotEmpty
        ? _cumulativeDistances.last
        : 0.0;
    _metricsNotifier.value = RouteMetrics(
      remainingDistanceMeters: totalDistance,
      remainingTime: _totalDuration,
      progress: 0,
    );
  }

  void start() {
    if (_routePoints.length < 2) {
      return;
    }
    _ticker.start();
  }

  void dispose() {
    _ticker.dispose();
  }

  void _onTick(Duration elapsed) {
    if (elapsed - _lastUpdate < _updateInterval) {
      return;
    }
    _lastUpdate = elapsed;
    final progress = (elapsed.inMilliseconds / _totalDuration.inMilliseconds)
        .clamp(0.0, 1.0);
    final index = (progress * (_routePoints.length - 1)).floor();
    final point = _routePoints[index];
    _mapController.moveCamera(CameraUpdate.newLatLng(point));

    final traveled = _routePoints.sublist(0, max(1, index + 1));
    final traveledLine = _traveledLine;
    if (traveledLine != null) {
      _mapController.updateLine(
        traveledLine,
        LineOptions(geometry: traveled),
      );
    }

    final remainingSeconds =
        (_totalDuration.inSeconds * (1 - progress)).ceil();
    final totalDistance = _cumulativeDistances.isNotEmpty
        ? _cumulativeDistances.last
        : 0.0;
    final traveledDistance = _cumulativeDistances.isNotEmpty
        ? _cumulativeDistances[index]
        : 0.0;
    final remainingDistance = max(0.0, totalDistance - traveledDistance);

    _metricsNotifier.value = RouteMetrics(
      remainingDistanceMeters: remainingDistance,
      remainingTime: Duration(seconds: max(0, remainingSeconds)),
      progress: progress,
    );

    if (progress >= 1.0) {
      _ticker.stop();
    }
  }

  List<double> _buildCumulativeDistances(List<LatLng> points) {
    final distances = <double>[0.0];
    var total = 0.0;
    for (var i = 1; i < points.length; i += 1) {
      total += _distanceBetween(points[i - 1], points[i]);
      distances.add(total);
    }
    return distances;
  }

  double _distanceBetween(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLon = _toRadians(b.longitude - a.longitude);
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);

    final h = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(h), sqrt(1 - h));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (pi / 180.0);
}
