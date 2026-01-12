import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../access_catalog.dart';
import '../gps_pip.dart';
import '../privacy_copy.dart';
import '../privacy_phase.dart';
import '../route_progress_controller.dart';
import '../routing_service.dart';
import '../stable_map_view.dart';
import '../state/demo_state.dart';
import '../theme/theme.dart';
import '../widgets/permission_prompt.dart';
import '../widgets/top_bar.dart';

const double kRouteCardHeight = 182;

class MapScreen extends StatefulWidget {
  final DemoState demoState;

  const MapScreen({
    super.key,
    required this.demoState,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  static const LatLng _routeStart = LatLng(46.0300, 14.5600);
  static const LatLng _routeDestination = LatLng(46.0593, 14.4976);
  static const double _routeStartZoom = 15.2;
  static const Duration _routeDuration = Duration(seconds: 96);

  final RoutingService _routingService = RoutingService();
  final ValueNotifier<RouteMetrics> _routeMetrics =
      ValueNotifier<RouteMetrics>(RouteMetrics.initial());

  AccessItem? _activePrompt;
  Timer? _promptTimer;
  Timer? _autoAdvanceTimer;

  RouteProgressController? _routeProgressController;
  bool _isRouteLoading = false;
  bool _routeStarted = false;
  int _consentCount = 0;

  @override
  void initState() {
    super.initState();
    _scheduleNextPrompt(const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _promptTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    _routeProgressController?.dispose();
    _routeMetrics.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const RepaintBoundary(child: StableMapView()),
          const Positioned.fill(child: DisturbanceHeatOverlay()),
          const Positioned(
            left: 0,
            right: 0,
            bottom: kRouteCardHeight + 28,
            child: IgnorePointer(
              child: Center(child: ScreenPinnedGpsPip()),
            ),
          ),
          const TopBar(),
          CenterOverlayHost(
            activePrompt: _activePrompt,
            phase: widget.demoState.currentPhase,
            onAllow: _grantPrompt,
            onContinue: _handleMaybeLater,
            onDismiss: _handleMaybeLater,
          ),
          BottomRouteCard(
            isLoading: _isRouteLoading,
            routeStarted: _routeStarted,
            metricsNotifier: _routeMetrics,
            consentCount: _consentCount,
            totalConsents: AccessCatalog.items.length,
            collectedSignals: widget.demoState.granted.length,
            onStartRoute: _startRoute,
          ),
        ],
      ),
    );
  }

  Future<void> _startRoute() async {
    if (_isRouteLoading || _routeStarted) {
      return;
    }
    setState(() {
      _isRouteLoading = true;
    });

    final mapController = await _awaitMapReady();
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(_routeStart, _routeStartZoom),
    );
    await Future.delayed(const Duration(milliseconds: 900));

    final routePoints = await _routingService.fetchWalkingRoute(
      start: _routeStart,
      destination: _routeDestination,
    );
    if (!mounted) {
      return;
    }

    if (routePoints.isEmpty) {
      setState(() {
        _isRouteLoading = false;
      });
      return;
    }

    _routeProgressController?.dispose();
    _routeProgressController = RouteProgressController(
      mapController: mapController,
      routePoints: routePoints,
      metricsNotifier: _routeMetrics,
      vsync: this,
      totalDuration: _routeDuration,
    );
    await _routeProgressController?.initialize();
    _routeProgressController?.start();

    setState(() {
      _isRouteLoading = false;
      _routeStarted = true;
    });
  }

  Future<MapLibreMapController> _awaitMapReady() async {
    final controller = StableMapView.controllerNotifier.value;
    if (controller != null && StableMapView.styleReadyNotifier.value) {
      return controller;
    }
    final completer = Completer<MapLibreMapController>();
    void listener() {
      final readyController = StableMapView.controllerNotifier.value;
      if (readyController != null && StableMapView.styleReadyNotifier.value) {
        StableMapView.controllerNotifier.removeListener(listener);
        StableMapView.styleReadyNotifier.removeListener(listener);
        completer.complete(readyController);
      }
    }

    StableMapView.controllerNotifier.addListener(listener);
    StableMapView.styleReadyNotifier.addListener(listener);
    return completer.future;
  }

  void _scheduleNextPrompt(Duration delay) {
    _promptTimer?.cancel();
    _promptTimer = Timer(delay, () {
      if (!mounted || _activePrompt != null) {
        return;
      }
      final candidate = widget.demoState.nextRequest();
      if (candidate == null) {
        return;
      }
      setState(() {
        _activePrompt = candidate;
      });
      _autoAdvanceTimer?.cancel();
      _autoAdvanceTimer = Timer(const Duration(seconds: 10), () {
        if (!mounted || _activePrompt == null) {
          return;
        }
        _dismissPrompt(showMessage: false, incrementConsent: true);
      });
    });
  }

  void _grantPrompt() {
    final prompt = _activePrompt;
    if (prompt == null) {
      return;
    }
    widget.demoState.grant(prompt.id);
    _dismissPrompt(showMessage: true, incrementConsent: true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Suggestion saved.')),
    );
  }

  void _handleMaybeLater() {
    _dismissPrompt(showMessage: false, incrementConsent: true);
  }

  void _dismissPrompt({
    bool showMessage = true,
    bool incrementConsent = false,
  }) {
    if (_activePrompt == null) {
      return;
    }
    setState(() {
      _activePrompt = null;
      if (incrementConsent) {
        _consentCount += 1;
      }
    });
    _autoAdvanceTimer?.cancel();
    if (showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            PrivacyCopy.denialMessage(widget.demoState.currentPhase),
          ),
        ),
      );
    }
    _scheduleNextPrompt(const Duration(seconds: 12));
  }
}

class DisturbanceHeatOverlay extends StatefulWidget {
  const DisturbanceHeatOverlay({super.key});

  @override
  State<DisturbanceHeatOverlay> createState() => _DisturbanceHeatOverlayState();
}

class _DisturbanceHeatOverlayState extends State<DisturbanceHeatOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          return CustomPaint(
            painter: _HeatmapPainter(pulse: _pulseController.value),
          );
        },
      ),
    );
  }
}

class CenterOverlayHost extends StatelessWidget {
  final AccessItem? activePrompt;
  final PrivacyPhase phase;
  final VoidCallback onAllow;
  final VoidCallback onContinue;
  final VoidCallback onDismiss;

  const CenterOverlayHost({
    super.key,
    required this.activePrompt,
    required this.phase,
    required this.onAllow,
    required this.onContinue,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (activePrompt == null) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: PermissionPrompt(
          item: activePrompt!,
          phase: phase,
          onAllow: onAllow,
          onContinue: onContinue,
          onDismiss: onDismiss,
        ),
      ),
    );
  }
}

class BottomRouteCard extends StatelessWidget {
  final bool isLoading;
  final bool routeStarted;
  final ValueNotifier<RouteMetrics> metricsNotifier;
  final int consentCount;
  final int totalConsents;
  final int collectedSignals;
  final VoidCallback onStartRoute;

  const BottomRouteCard({
    super.key,
    required this.isLoading,
    required this.routeStarted,
    required this.metricsNotifier,
    required this.consentCount,
    required this.totalConsents,
    required this.collectedSignals,
    required this.onStartRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: kRouteCardHeight,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Quiet Route',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        _TwinIndicator(opacity: _twinOpacity()),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ljubljana → Tivoli Park',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<RouteMetrics>(
                      valueListenable: metricsNotifier,
                      builder: (context, metrics, _) {
                        final minutes = max(1, metrics.remainingTime.inMinutes + 1);
                        final distanceKm = metrics.remainingDistanceMeters / 1000;
                        final distanceLabel = distanceKm > 0
                            ? '${distanceKm.toStringAsFixed(1)} km'
                            : '—';
                        return Row(
                          children: [
                            _InfoChip(
                              label: routeStarted ? '$minutes min' : 'ETA —',
                              color: CozyTheme.mint,
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              label: routeStarted ? distanceLabel : 'Distance —',
                              color: CozyTheme.lavender,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _BadgeChip(
                          label: 'Consent: $consentCount/∞',
                          color: CozyTheme.peach,
                        ),
                        const SizedBox(width: 8),
                        _BadgeChip(
                          label: 'Collected signals: $collectedSignals',
                          color: CozyTheme.mint,
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: isLoading ? null : onStartRoute,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CozyTheme.ink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Start route'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _twinOpacity() {
    if (totalConsents == 0) {
      return 0.35;
    }
    return (0.35 + (consentCount / totalConsents) * 0.65).clamp(0.35, 1.0);
  }
}

class _TwinIndicator extends StatelessWidget {
  final double opacity;

  const _TwinIndicator({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: CozyTheme.lavender.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.auto_awesome_rounded, color: CozyTheme.ink),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _BadgeChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: CozyTheme.ink, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: CozyTheme.ink, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final double pulse;

  const _HeatmapPainter({
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final blobs = <_HeatBlob>[
      _HeatBlob(Offset(size.width * 0.56, size.height * 0.36), 120, 0.22),
      _HeatBlob(Offset(size.width * 0.64, size.height * 0.42), 100, 0.26),
      _HeatBlob(Offset(size.width * 0.76, size.height * 0.5), 130, 0.2),
      _HeatBlob(Offset(size.width * 0.42, size.height * 0.52), 110, 0.18),
      _HeatBlob(Offset(size.width * 0.3, size.height * 0.6), 130, 0.14),
      _HeatBlob(Offset(size.width * 0.22, size.height * 0.22), 150, 0.1),
      _HeatBlob(Offset(size.width * 0.5, size.height * 0.72), 140, 0.16),
    ];

    for (final blob in blobs) {
      final intensity = (blob.intensity + (pulse * 0.08)).clamp(0.05, 0.45);
      final paint = Paint()
        ..color = CozyTheme.mint.withOpacity(intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
      canvas.drawCircle(blob.center, blob.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.pulse != pulse;
  }
}

class _HeatBlob {
  final Offset center;
  final double radius;
  final double intensity;

  const _HeatBlob(this.center, this.radius, this.intensity);
}
