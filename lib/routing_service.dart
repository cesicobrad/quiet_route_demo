import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class RoutingService {
  static const String _mapTilerKey = 'PEK7V4X8DK3A0P2AIZdI';
  static const String _fallbackAsset = 'assets/routes/tivoli_route.geojson';

  Future<List<LatLng>> fetchWalkingRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.maptiler.com/directions/v1/walking/'
        '${start.longitude},${start.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?key=$_mapTilerKey&geometries=geojson&overview=full',
      );
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        final routes = decoded['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final geometry = routes.first['geometry'] as Map<String, dynamic>?;
          final coordinates = geometry?['coordinates'] as List<dynamic>?;
          if (coordinates != null && coordinates.isNotEmpty) {
            return coordinates
                .map((point) => LatLng(point[1] as double, point[0] as double))
                .toList();
          }
        }
      }
    } catch (_) {
      // Fall back to bundled route.
    }
    return _loadFallbackRoute();
  }

  Future<List<LatLng>> _loadFallbackRoute() async {
    final content = await rootBundle.loadString(_fallbackAsset);
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    final features = decoded['features'] as List<dynamic>?;
    if (features == null || features.isEmpty) {
      return [];
    }
    final geometry = features.first['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'] as List<dynamic>?;
    if (coordinates == null || coordinates.isEmpty) {
      return [];
    }
    return coordinates
        .map((point) => LatLng(point[1] as double, point[0] as double))
        .toList();
  }
}
