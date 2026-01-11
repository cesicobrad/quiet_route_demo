import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../access_catalog.dart';
import '../privacy_copy.dart';
import '../state/demo_state.dart';
import '../theme/theme.dart';
import '../widgets/cozy_route_card.dart';
import '../widgets/cozy_top_bar.dart';
import '../widgets/permission_prompt_sheet.dart';
import 'access_catalog_screen.dart';

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
  static const LatLng _ljubljanaCenter = LatLng(46.0569, 14.5058);
  static const String _mapStyle = '''
{
  "version": 8,
  "sources": {
    "osm": {
      "type": "raster",
      "tiles": ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
      "tileSize": 256,
      "attribution": "© OpenStreetMap contributors"
    }
  },
  "layers": [
    {
      "id": "osm",
      "type": "raster",
      "source": "osm"
    }
  ]
}
''';

  final List<String> _destinations = const [
    'Tivoli Park',
    'Prešeren Square',
    'Metelkova',
  ];

  String? _selectedDestination;
  bool _isCalculating = false;

  int _routeMinutes = 0;
  int _calmScore = 0;

  AccessItem? _activePrompt;
  bool _showSystemOverview = false;

  Timer? _promptTimer;
  Timer? _autoAdvanceTimer;

  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _scheduleNextPrompt(const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _promptTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapLibreMap(
            styleString: _mapStyle,
            initialCameraPosition: const CameraPosition(
              target: _ljubljanaCenter,
              zoom: 13.6,
            ),
            minMaxZoomPreference: const MinMaxZoomPreference(11, 18),
            compassEnabled: false,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _HeatmapPainter(pulse: _pulseController.value),
                  );
                },
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _RoutePainter(
                  destination: _selectedDestination,
                  showRoute:
                      !_isCalculating && _selectedDestination != null && _routeMinutes > 0,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                CozyTopBar(onSettings: _toggleSystemOverview),
                _buildDestinationChips(),
                _buildStatusStrip(),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _legendBadge(),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _buildRouteCard(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          if (_activePrompt != null)
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: PermissionPromptSheet(
                  item: _activePrompt!,
                  phase: widget.demoState.currentPhase,
                  onAllow: _grantPrompt,
                  onContinue: _dismissPrompt,
                  onDismiss: _dismissPrompt,
                ),
              ),
            ),
          if (_showSystemOverview)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleSystemOverview,
                child: Container(
                  color: Colors.black.withOpacity(0.15),
                ),
              ),
            ),
          if (_showSystemOverview)
            Positioned.fill(
              child: SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AccessCatalogScreen(
                    demoState: widget.demoState,
                    onClose: _toggleSystemOverview,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _legendBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CozyTheme.ink.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: CozyTheme.mint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Calmer zones',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStrip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          _statusPill(
            label: 'Quietness',
            value: _selectedDestination == null ? '82' : '$_calmScore',
            color: CozyTheme.mint,
          ),
          const SizedBox(width: 10),
          _statusPill(
            label: 'Air',
            value: 'Fresh',
            color: CozyTheme.lavender,
          ),
          const SizedBox(width: 10),
          _statusPill(
            label: 'Crowds',
            value: 'Low',
            color: CozyTheme.peach,
          ),
        ],
      ),
    );
  }

  Widget _statusPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: CozyTheme.ink.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _destinations.map((destination) {
            final selected = _selectedDestination == destination;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ChoiceChip(
                label: Text(destination),
                selected: selected,
                selectedColor: CozyTheme.lavender.withOpacity(0.6),
                backgroundColor: Colors.white.withOpacity(0.9),
                labelStyle: TextStyle(
                  color: CozyTheme.ink,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
                onSelected: (_) => _selectDestination(destination),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRouteCard() {
    if (_selectedDestination == null) {
      return const SizedBox.shrink();
    }
    if (_isCalculating) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      CozyTheme.lavender,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Listening to the city…',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, _) {
                          return _ShimmerBar(progress: _shimmerController.value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_routeMinutes == 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CozyRouteCard(
        key: ValueKey(_selectedDestination),
        destination: _selectedDestination!,
        minutes: _routeMinutes,
        calmScore: _calmScore,
      ),
    );
  }

  Future<void> _selectDestination(String destination) async {
    if (_isCalculating) {
      return;
    }
    setState(() {
      _selectedDestination = destination;
      _isCalculating = true;
      _routeMinutes = 0;
    });

    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) {
      return;
    }
    final random = Random(destination.hashCode);
    final minutes = 12 + random.nextInt(14);
    final calm = destination == 'Tivoli Park'
        ? 86 + random.nextInt(8)
        : 55 + random.nextInt(30);
    setState(() {
      _isCalculating = false;
      _routeMinutes = minutes;
      _calmScore = calm;
    });
    widget.demoState.registerRoutePlanned();
    if (_activePrompt == null) {
      _scheduleNextPrompt(const Duration(seconds: 2));
    }
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
        _dismissPrompt(showMessage: false);
      });
    });
  }

  void _grantPrompt() {
    final prompt = _activePrompt;
    if (prompt == null) {
      return;
    }
    widget.demoState.grant(prompt.id);
    _dismissPrompt(showMessage: true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Suggestion saved gently.')),
    );
  }

  void _dismissPrompt({bool showMessage = true}) {
    if (_activePrompt == null) {
      return;
    }
    setState(() {
      _activePrompt = null;
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

  void _toggleSystemOverview() {
    setState(() {
      _showSystemOverview = !_showSystemOverview;
    });
  }
}

class _ShimmerBar extends StatelessWidget {
  final double progress;

  const _ShimmerBar({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: CozyTheme.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Align(
          alignment: Alignment(-1 + (progress * 2), 0),
          child: Container(
            width: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  CozyTheme.lavender.withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
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
      _HeatBlob(Offset(size.width * 0.55, size.height * 0.35), 110, 0.2),
      _HeatBlob(Offset(size.width * 0.65, size.height * 0.42), 90, 0.26),
      _HeatBlob(Offset(size.width * 0.75, size.height * 0.5), 120, 0.22),
      _HeatBlob(Offset(size.width * 0.4, size.height * 0.45), 100, 0.18),
      _HeatBlob(Offset(size.width * 0.3, size.height * 0.6), 120, 0.14),
      _HeatBlob(Offset(size.width * 0.18, size.height * 0.2), 140, 0.1),
      _HeatBlob(Offset(size.width * 0.52, size.height * 0.72), 130, 0.16),
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

class _HeatBlob {
  final Offset center;
  final double radius;
  final double intensity;

  const _HeatBlob(this.center, this.radius, this.intensity);
}
