import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../state/showcase_state.dart';
import '../theme/theme.dart';
import '../widgets/heatmap_painter.dart';
import '../widgets/prompt_card.dart';
import '../widgets/route_card.dart';
import '../widgets/top_bar.dart';
import 'system_screen.dart';

class MapScreen extends StatefulWidget {
  final ShowcaseState showcaseState;

  const MapScreen({
    super.key,
    required this.showcaseState,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin {
  static const LatLng _ljubljanaCenter = LatLng(46.0569, 14.5058);
  static const double _defaultZoom = 13.5;
  static const Alignment _pipAlignment = Alignment(0.25, 0.35);
  static const String _mapStyleUrl =
      'https://api.maptiler.com/maps/streets/style.json?key=PEK7V4X8DK3A0P2AIZdI';
  static const String _fallbackMapUrl =
      'https://api.maptiler.com/maps/streets/static/14.5058,46.0569,13.5/1280x720.png?key=PEK7V4X8DK3A0P2AIZdI';

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

  bool _mapLoaded = false;
  bool _showFallback = false;
  String? _mapErrorMessage;

  Timer? _fallbackTimer;
  MapLibreMapController? _mapController;

  late final AnimationController _pulseController;
  late final AnimationController _gpsPulseController;

  bool _destinationSheetOpen = false;
  Offset _pipOffsetFromCenter = Offset.zero;

  @override
  void initState() {
    super.initState();
    widget.showcaseState.addListener(_handleShowcaseUpdates);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _gpsPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _fallbackTimer = Timer(const Duration(seconds: 12), () {
      if (!mounted || _mapLoaded) {
        return;
      }
      setState(() {
        _showFallback = true;
        _mapErrorMessage =
            'Map is taking longer than expected. Showing a static preview.';
      });
    });
  }

  @override
  void dispose() {
    widget.showcaseState.removeListener(_handleShowcaseUpdates);
    _fallbackTimer?.cancel();
    _pulseController.dispose();
    _gpsPulseController.dispose();
    super.dispose();
  }

  void _handleShowcaseUpdates() {
    final destination = widget.showcaseState.pendingDestination;
    if (destination != null && !_destinationSheetOpen) {
      _openDestinationSheet(autoSelect: destination);
      widget.showcaseState.consumeDestinationRequest();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.showcaseState,
      builder: (context, _) {
        final state = widget.showcaseState;
        return LayoutBuilder(
          builder: (context, constraints) {
            _pipOffsetFromCenter = Offset(
              constraints.maxWidth * _pipAlignment.x / 2,
              constraints.maxHeight * _pipAlignment.y / 2,
            );
            return Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: MapLibreMap(
                      styleString: _mapStyleUrl,
                      initialCameraPosition: const CameraPosition(
                        target: _ljubljanaCenter,
                        zoom: _defaultZoom,
                      ),
                      minMaxZoomPreference: const MinMaxZoomPreference(11, 18),
                      compassEnabled: false,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _mapErrorMessage = null;
                        });
                      },
                      onStyleLoadedCallback: () {
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _mapLoaded = true;
                          _showFallback = false;
                          _mapErrorMessage = null;
                        });
                      },
                    ),
                  ),
                  if (_showFallback)
                    Positioned.fill(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            _fallbackMapUrl,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            color: CozyTheme.cream.withOpacity(0.08),
                          ),
                        ],
                      ),
                    ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: HeatmapPainter(
                              pulse: _pulseController.value,
                              intensityFactor: state.heatmapIntensity,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _RoutePainter(
                          destination: state.destination,
                          showRoute: !state.isCalculating &&
                              state.destination != null &&
                              state.routeMinutes > 0,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _buildLocationPip(state),
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
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: Tween<double>(begin: 0.98, end: 1)
                                        .animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: state.activePrompt == null
                                  ? const SizedBox.shrink()
                                  : _PromptCardStack(
                                      key: ValueKey(state.activePrompt!.title),
                                      state: state,
                                      maxWidth:
                                          min(constraints.maxWidth * 0.9, 420),
                                    ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: RouteCard(
                            destination: state.destination,
                            minutes: state.routeMinutes,
                            calmScore: state.calmScore,
                            consentCount: state.consentCount,
                            isCalculating: state.isCalculating,
                            isPlaying: state.isPlaying,
                            onStart: state.startShowcase,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 20,
                    bottom: 190,
                    child: SafeArea(
                      child: _buildRecenterButton(),
                    ),
                  ),
                  if (_mapErrorMessage != null)
                    Positioned(
                      left: 20,
                      right: 20,
                      top: 84,
                      child: SafeArea(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: CozyTheme.ink.withOpacity(0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: CozyTheme.peach),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _mapErrorMessage!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                            showcaseState: state,
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
      },
    );
  }

  Widget _buildLocationPip(ShowcaseState state) {
    return AnimatedBuilder(
      animation: _gpsPulseController,
      builder: (context, _) {
        final pulse = _gpsPulseController.value;
        final pulseSize = 34 + (pulse * 18);
        return Align(
          alignment: _pipAlignment,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: pulseSize,
                height: pulseSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CozyTheme.mint.withOpacity(0.3 * (1 - pulse)),
                ),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CozyTheme.mint,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: CozyTheme.ink.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              if (state.showTwin)
                Positioned(
                  left: 18,
                  top: -34,
                  child: Opacity(
                    opacity: state.twinOpacity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: CozyTheme.ink.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_outline, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Twin',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
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

  Widget _buildRecenterButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CozyTheme.ink.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.my_location_rounded),
        color: CozyTheme.ink,
        onPressed: _recenterMap,
        tooltip: 'Recenter',
      ),
    );
  }

  Future<void> _recenterMap() async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(_ljubljanaCenter, _defaultZoom),
    );
    if (_pipOffsetFromCenter.dy.abs() > 1) {
      await controller.animateCamera(
        CameraUpdate.scrollBy(0, _pipOffsetFromCenter.dy),
      );
    }
  }

  Future<void> _openDestinationSheet({String? autoSelect}) async {
    if (_destinationSheetOpen) {
      return;
    }
    _destinationSheetOpen = true;
    if (autoSelect != null) {
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) {
          return;
        }
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(autoSelect);
        }
      });
    }
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
    final route = _buildRouteDetails(selected);
    await widget.showcaseState.startRouteCalculation(
      destination: selected,
      minutes: route.minutes,
      calmScore: route.calmScore,
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

class _PromptCardStack extends StatelessWidget {
  final ShowcaseState state;
  final double maxWidth;

  const _PromptCardStack({
    super.key,
    required this.state,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final prompt = state.activePrompt;
    if (prompt == null) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: PromptCard(
            title: prompt.title,
            subtitle: prompt.subtitle,
            body: prompt.body,
            responseLine: state.promptResponse,
            buttonsEnabled: false,
          ),
        ),
        if (state.showQueueIndicator)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: CozyTheme.ink.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                'Requests waiting: ${state.queueCount}',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: CozyTheme.muted),
              ),
            ),
          ),
      ],
    );
  }
}

class _RoutePainter extends CustomPainter {
  final String? destination;
  final bool showRoute;

  const _RoutePainter({
    required this.destination,
    required this.showRoute,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showRoute || destination == null) {
      return;
    }
    final paint = Paint()
      ..color = CozyTheme.ink.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(size.width * 0.18, size.height * 0.78);
    if (destination == 'Tivoli Park') {
      path
        ..quadraticBezierTo(
          size.width * 0.2,
          size.height * 0.45,
          size.width * 0.18,
          size.height * 0.22,
        );
    } else if (destination == 'Prešeren Square') {
      path
        ..quadraticBezierTo(
          size.width * 0.38,
          size.height * 0.55,
          size.width * 0.52,
          size.height * 0.32,
        );
    } else {
      path
        ..quadraticBezierTo(
          size.width * 0.45,
          size.height * 0.6,
          size.width * 0.78,
          size.height * 0.62,
        );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.destination != destination ||
        oldDelegate.showRoute != showRoute;
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
