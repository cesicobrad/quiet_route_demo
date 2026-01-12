import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

class RoutingService {
  final http.Client _client;
  final String? apiKey;

  List<LatLng>? _cachedRoute;
  LatLng? _cachedFrom;
  LatLng? _cachedTo;

  RoutingService({http.Client? client, this.apiKey})
      : _client = client ?? http.Client();

  Future<List<LatLng>> getWalkingRoute(LatLng from, LatLng to) async {
    if (_cachedRoute != null && _cachedFrom == from && _cachedTo == to) {
      return _cachedRoute!;
    }

    final route = await _fetchFromApi(from, to) ?? await _loadFallback();
    _cachedRoute = route;
    _cachedFrom = from;
    _cachedTo = to;
    return route;
  }

  Future<List<LatLng>?> _fetchFromApi(LatLng from, LatLng to) async {
    final key = apiKey;
    if (key == null || key.isEmpty) {
      return null;
    }
    final url = Uri.parse(
      'https://api.maptiler.com/directions/v1/foot/'
      '${from.longitude},${from.latitude};'
      '${to.longitude},${to.latitude}'
      '?key=$key&geometries=geojson',
    );

    try {
      final response = await _client.get(url);
      if (response.statusCode != 200) {
        return null;
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = payload['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        return null;
      }
      final geometry = (routes.first as Map<String, dynamic>)['geometry']
          as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'] as List<dynamic>?;
      if (coordinates == null || coordinates.isEmpty) {
        return null;
      }
      return coordinates.map((point) {
        final list = point as List<dynamic>;
        return LatLng(
          (list[1] as num).toDouble(),
          (list[0] as num).toDouble(),
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<LatLng>> _loadFallback() async {
    final jsonString =
        await rootBundle.loadString('assets/routes/tivoli_route.geojson');
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>?;
    if (features == null || features.isEmpty) {
      return _fallbackLine();
    }
    final geometry =
        (features.first as Map<String, dynamic>)['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'] as List<dynamic>?;
    if (coordinates == null || coordinates.isEmpty) {
      return _fallbackLine();
    }
    return coordinates.map((point) {
      final list = point as List<dynamic>;
      return LatLng(
        (list[1] as num).toDouble(),
        (list[0] as num).toDouble(),
      );
    }).toList();
  }

  List<LatLng> _fallbackLine() {
    const start = LatLng(46.0511, 14.5060);
    const end = LatLng(46.0593, 14.4976);
    final points = <LatLng>[];
    for (var i = 0; i <= 32; i++) {
      final t = i / 32;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      final wiggle = sin(t * pi) * 0.0006;
      points.add(LatLng(lat + wiggle, lng - wiggle));
    }
    return points;
  }
}
