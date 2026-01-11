import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../services/routing_service.dart';
import '../state/playback_state.dart';
import '../theme/theme.dart';
import '../widgets/gps_pip.dart';
import '../widgets/heat_overlay.dart';
import '../widgets/prompt_card.dart';
import '../widgets/route_card.dart';
import '../widgets/top_bar.dart';
import 'system_screen.dart';

class MapScreen extends StatefulWidget {
  final PlaybackState playbackState;

  const MapScreen({
    super.key,
    required this.playbackState,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin {
  static const LatLng _ljubljanaCenter = LatLng(46.0569, 14.5058);
  static const LatLng _tivoliDestination = LatLng(46.0597, 14.4911);
  static const double _defaultZoom = 13.5;
  static const double _routeCardHeight = 220;
  static const String _mapStyleUrl =
      'https://api.maptiler.com/maps/streets/style.json?key=PEK7V4X8DK3A0P2AIZdI';
  static const String _maptilerKey = 'PEK7V4X8DK3A0P2AIZdI';

  final Map<String, String> _destinationSubtitles = const {
    'Tivoli Park': 'Tree-lined paths and quiet lawns.',
    'Prešeren Square': 'City center with room to pause.',
    'Metelkova': 'Creative quarter with tucked-away streets.',
  };

  final List<String> _destinations = const [
    'Tivoli Park',
    'Prešeren Square',
    'Metelkova',
  ];

  final RoutingService _routingService = RoutingService(apiKey: _maptilerKey);

  late final Widget _mapWidget;
  MapLibreMapController? _mapController;
  bool _styleLoaded = false;

  int _lastRouteRequestId = 0;
  Line? _routeLine;

  bool _destinationSheetOpen = false;

  @override
  void initState() {
    super.initState();
    widget.playbackState.addListener(_handlePlaybackUpdates);
    _mapWidget = _MapSurface(
      styleUrl: _mapStyleUrl,
      initialTarget: _ljubljanaCenter,
      zoom: _defaultZoom,
      onMapCreated: _onMapCreated,
      onStyleLoaded: _onStyleLoaded,
    );
  }

  @override
  void dispose() {
    widget.playbackState.removeListener(_handlePlaybackUpdates);
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  void _onStyleLoaded() {
    _styleLoaded = true;
  }

  void _handlePlaybackUpdates() {
    final state = widget.playbackState;
    if (state.routeRequestId != _lastRouteRequestId) {
      _lastRouteRequestId = state.routeRequestId;
      _recalculateRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.playbackState,
      builder: (context, _) {
        final state = widget.playbackState;
        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(child: _mapWidget),
              Positioned.fill(
                child: DisturbanceHeatOverlay(show: state.showHeat),
              ),
              Align(
                alignment: const Alignment(0, 0.55),
                child: ScreenPinnedGpsPip(
                  showTwin: state.showTwin,
                  twinOpacity: state.twinOpacity,
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    TopBar(
                      onSystemPressed: () => state.openSystemScreen(),
                      onDestinations: _openDestinationSheet,
                      collectedSignals: state.collectedSignalsCount,
                    ),
                    Expanded(
                      child: Center(
                        child: _CenterOverlayHost(state: state),
                      ),
                    ),
                    SizedBox(
                      height: _routeCardHeight,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RouteCard(
                          destination: state.destination,
                          minutes: state.routeMinutes,
                          calmScore: state.calmScore,
                          consentCount: state.consentScore,
                          isCalculating: state.routeCalculating,
                          isPlaying: state.isPlaying,
                          statusText: state.bottomStatusText,
                          onStart: state.startPlayback,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (state.showSystemScreen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: state.closeSystemScreen,
                    child: Container(
                      color: Colors.black.withOpacity(0.18),
                    ),
                  ),
                ),
              if (state.showSystemScreen)
                Positioned.fill(
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SystemScreen(
                        playbackState: state,
                        onClose: state.closeSystemScreen,
                        autoScroll: state.autoScrollSystem,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _recalculateRoute() async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) {
      widget.playbackState.routeCalculating = false;
      widget.playbackState.notifyListeners();
      return;
    }
    final camera = await controller.cameraPosition;
    final from = camera?.target ?? _ljubljanaCenter;
    final route = await _routingService.getWalkingRoute(from, _tivoliDestination);
    await _drawRoute(route);
    widget.playbackState.applyRouteResult(minutes: 18, calmScore: 82);
  }

  Future<void> _drawRoute(List<LatLng> route) async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }
    if (_routeLine != null) {
      await controller.removeLine(_routeLine!);
      _routeLine = null;
    }
    final line = await controller.addLine(
      LineOptions(
        geometry: route,
        lineColor: '#2C2C2C',
        lineWidth: 4,
        lineOpacity: 0.6,
      ),
    );
    _routeLine = line;
  }

  Future<void> _openDestinationSheet() async {
    if (_destinationSheetOpen) {
      return;
    }
    _destinationSheetOpen = true;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: CozyTheme.ink.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Text(
                  'Destinations',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ..._destinations.map((destination) {
                  final subtitle = _destinationSubtitles[destination] ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(destination),
                      subtitle: Text(subtitle),
                      trailing:
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        Navigator.of(context).pop(destination);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
    _destinationSheetOpen = false;
    if (selected == null) {
      return;
    }
    widget.playbackState.destination = selected;
    widget.playbackState.bottomStatusText = 'Calculating route…';
    widget.playbackState.routeCalculating = true;
    widget.playbackState.notifyListeners();
    final details = _buildRouteDetails(selected);
    widget.playbackState.applyRouteResult(
      minutes: details.minutes,
      calmScore: details.calmScore,
    );
  }

  _RouteDetails _buildRouteDetails(String destination) {
    if (destination == 'Tivoli Park') {
      return const _RouteDetails(minutes: 18, calmScore: 82);
    }
    final random = Random(destination.hashCode);
    final minutes = 12 + random.nextInt(14);
    final calm = destination == 'Prešeren Square'
        ? 62 + random.nextInt(18)
        : 45 + random.nextInt(20);
    return _RouteDetails(minutes: minutes, calmScore: calm);
  }
}

class _MapSurface extends StatelessWidget {
  final String styleUrl;
  final LatLng initialTarget;
  final double zoom;
  final ValueChanged<MapLibreMapController> onMapCreated;
  final VoidCallback onStyleLoaded;

  const _MapSurface({
    required this.styleUrl,
    required this.initialTarget,
    required this.zoom,
    required this.onMapCreated,
    required this.onStyleLoaded,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: MapLibreMap(
        styleString: styleUrl,
        initialCameraPosition: CameraPosition(
          target: initialTarget,
          zoom: zoom,
        ),
        minMaxZoomPreference: const MinMaxZoomPreference(11, 18),
        compassEnabled: false,
        onMapCreated: onMapCreated,
        onStyleLoadedCallback: onStyleLoaded,
      ),
    );
  }
}

class _CenterOverlayHost extends StatelessWidget {
  final PlaybackState state;

  const _CenterOverlayHost({required this.state});

  @override
  Widget build(BuildContext context) {
    final card = state.activeCard;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: card == null
          ? const SizedBox.shrink()
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: PromptCard(
                title: card.title,
                subtitle: card.subtitle,
                body: card.body,
                responseLine: card.responseLine,
                requestsWaiting: card.requestsWaiting,
                showActions: card.type == OverlayCardType.prompt,
                buttonsEnabled: false,
              ),
            ),
    );
  }
}

class _RouteDetails {
  final int minutes;
  final int calmScore;

  const _RouteDetails({
    required this.minutes,
    required this.calmScore,
  });
}
