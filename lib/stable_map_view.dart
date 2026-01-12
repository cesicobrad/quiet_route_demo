import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class StableMapView extends StatefulWidget {
  static const LatLng initialCenter = LatLng(46.0300, 14.5600);
  static const double initialZoom = 11.8;
  static const String mapStyleUrl =
      'https://api.maptiler.com/maps/streets/style.json?key=PEK7V4X8DK3A0P2AIZdI';

  static final ValueNotifier<MapLibreMapController?> controllerNotifier =
      ValueNotifier<MapLibreMapController?>(null);
  static final ValueNotifier<bool> styleReadyNotifier =
      ValueNotifier<bool>(false);

  const StableMapView({super.key});

  @override
  State<StableMapView> createState() => _StableMapViewState();
}

class _StableMapViewState extends State<StableMapView> {
  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      styleString: StableMapView.mapStyleUrl,
      initialCameraPosition: const CameraPosition(
        target: StableMapView.initialCenter,
        zoom: StableMapView.initialZoom,
      ),
      minMaxZoomPreference: const MinMaxZoomPreference(11, 18),
      compassEnabled: false,
      onMapCreated: (controller) {
        StableMapView.controllerNotifier.value = controller;
      },
      onStyleLoadedCallback: () {
        StableMapView.styleReadyNotifier.value = true;
      },
    );
  }
}
