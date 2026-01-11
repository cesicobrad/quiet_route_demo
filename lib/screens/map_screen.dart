import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

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

class _MapScreenState extends State<MapScreen> {
  final List<String> _destinations = const [
    'Tivoli Park',
    'Prešeren Square',
    'Metelkova',
  ];

  String? _selectedDestination;
  bool _isCalculating = false;
  bool _hasShownPrompt = false;
  bool _isRunningScriptedDemo = false;

  int _routeMinutes = 0;
  int _calmScore = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.demoState,
          builder: (context, _) {
            return Column(
              children: [
                CozyTopBar(onSettings: _openSettings),
                _buildDestinationChips(),
                _buildStatusStrip(),
                Expanded(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size = constraints.biggest;
                              return Stack(
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _MapPainter(),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _HeatmapPainter(),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _RoutePainter(
                                        destination: _selectedDestination,
                                        showRoute: !_isCalculating &&
                                            _selectedDestination != null,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 18,
                                    bottom: 18,
                                    child: _legendBadge(),
                                  ),
                                  ..._buildMapLabels(size),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: _buildRouteCard(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _legendBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: CozyTheme.peach,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Quietness heatmap',
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
          color: Colors.white,
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

  List<Widget> _buildMapLabels(Size mapSize) {
    return [
      _mapLabel(
        mapSize,
        const Offset(0.12, 0.18),
        'Tivoli Park',
        CozyTheme.mint,
      ),
      _mapLabel(
        mapSize,
        const Offset(0.52, 0.33),
        'Prešeren Sq.',
        CozyTheme.lavender,
      ),
      _mapLabel(
        mapSize,
        const Offset(0.74, 0.44),
        'Rail Station',
        CozyTheme.peach,
      ),
      _mapLabel(
        mapSize,
        const Offset(0.78, 0.63),
        'Metelkova',
        CozyTheme.peach,
      ),
    ];
  }

  Widget _mapLabel(Size mapSize, Offset anchor, String label, Color color) {
    return Positioned(
      left: anchor.dx * mapSize.width,
      top: anchor.dy * mapSize.height,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: CozyTheme.ink),
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
                backgroundColor: Colors.white,
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
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'Calculating…',
                  style: Theme.of(context).textTheme.titleMedium,
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
      padding: const EdgeInsets.only(bottom: 16),
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
    if (!_hasShownPrompt) {
      _hasShownPrompt = true;
      await _showNextPermission();
    }
  }

  Future<void> _showNextPermission() async {
    final candidate = widget.demoState.nextRequest();
    if (!mounted || candidate == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PermissionPromptSheet(
          item: candidate,
          phase: widget.demoState.currentPhase,
          onAllow: () {
            widget.demoState.grant(candidate.id);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(this.context).showSnackBar(
              const SnackBar(content: Text('Permission saved gently.')),
            );
          },
          onDeny: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(this.context).showSnackBar(
              SnackBar(
                content:
                    Text(PrivacyCopy.denialMessage(widget.demoState.currentPhase)),
              ),
            );
          },
        );
      },
    );
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: CozyTheme.muted.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Text('Demo controls', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Demo Mode',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Switch(
                    value: widget.demoState.demoMode,
                    activeColor: CozyTheme.mint,
                    onChanged: (value) {
                      widget.demoState.toggleDemoMode(value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CozyTheme.lavender,
                  foregroundColor: CozyTheme.ink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _isRunningScriptedDemo ? null : () => _runScriptedDemo(),
                child: const Text('Run scripted demo'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: CozyTheme.muted,
                  side: BorderSide(color: CozyTheme.muted.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  widget.demoState.reset();
                  setState(() {
                    _selectedDestination = null;
                    _routeMinutes = 0;
                    _calmScore = 0;
                    _isCalculating = false;
                    _hasShownPrompt = false;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Reset demo'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _runScriptedDemo() async {
    if (!widget.demoState.demoMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Turn on Demo Mode to run the script.')),
      );
      return;
    }
    if (_isRunningScriptedDemo) {
      return;
    }
    _isRunningScriptedDemo = true;
    Navigator.of(context).pop();

    const destinations = ['Tivoli Park', 'Prešeren Square', 'Metelkova'];
    await _selectDestination(destinations.first);
    await Future.delayed(const Duration(milliseconds: 900));
    await _showNextPermission();
    await Future.delayed(const Duration(milliseconds: 900));
    await _showNextPermission();
    await Future.delayed(const Duration(milliseconds: 900));
    await _showNextPermission();

    if (!mounted) {
      _isRunningScriptedDemo = false;
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AccessCatalogScreen(
          demoState: widget.demoState,
        ),
      ),
    );
    _isRunningScriptedDemo = false;
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = CozyTheme.cream;
    canvas.drawRect(Offset.zero & size, background);

    final gridPaint = Paint()
      ..color = CozyTheme.mint.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const gridSize = 40.0;
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final riverPaint = Paint()
      ..color = CozyTheme.lavender.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    final riverPath = Path()
      ..moveTo(size.width * 0.02, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.12,
        size.width * 0.52,
        size.height * 0.28,
      )
      ..quadraticBezierTo(
        size.width * 0.68,
        size.height * 0.45,
        size.width * 0.96,
        size.height * 0.7,
      );
    canvas.drawPath(riverPath, riverPaint);

    final parkPaint = Paint()
      ..color = CozyTheme.mint.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    final tivoliRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.08, size.height * 0.12,
          size.width * 0.22, size.height * 0.18),
      const Radius.circular(22),
    );
    canvas.drawRRect(tivoliRect, parkPaint);

    final plazaPaint = Paint()
      ..color = CozyTheme.peach.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    final plazaRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.47, size.height * 0.28,
          size.width * 0.12, size.height * 0.08),
      const Radius.circular(16),
    );
    canvas.drawRRect(plazaRect, plazaPaint);

    final streetPaint = Paint()
      ..color = CozyTheme.peach.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final streets = [
      [
        Offset(size.width * 0.08, size.height * 0.75),
        Offset(size.width * 0.38, size.height * 0.6),
      ],
      [
        Offset(size.width * 0.18, size.height * 0.42),
        Offset(size.width * 0.58, size.height * 0.4),
      ],
      [
        Offset(size.width * 0.6, size.height * 0.15),
        Offset(size.width * 0.88, size.height * 0.33),
      ],
      [
        Offset(size.width * 0.28, size.height * 0.9),
        Offset(size.width * 0.82, size.height * 0.8),
      ],
      [
        Offset(size.width * 0.5, size.height * 0.55),
        Offset(size.width * 0.8, size.height * 0.64),
      ],
      [
        Offset(size.width * 0.35, size.height * 0.22),
        Offset(size.width * 0.62, size.height * 0.28),
      ],
    ];
    for (final segment in streets) {
      canvas.drawLine(segment.first, segment.last, streetPaint);
    }

    final bridgePaint = Paint()
      ..color = CozyTheme.ink.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(size.width * 0.45, size.height * 0.3),
      Offset(size.width * 0.52, size.height * 0.28),
      bridgePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.45),
      Offset(size.width * 0.66, size.height * 0.48),
      bridgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeatmapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blobs = <_HeatBlob>[
      _HeatBlob(Offset(size.width * 0.55, size.height * 0.35), 90, 0.35),
      _HeatBlob(Offset(size.width * 0.65, size.height * 0.42), 70, 0.3),
      _HeatBlob(Offset(size.width * 0.75, size.height * 0.5), 80, 0.32),
      _HeatBlob(Offset(size.width * 0.4, size.height * 0.45), 60, 0.22),
      _HeatBlob(Offset(size.width * 0.3, size.height * 0.6), 65, 0.2),
      _HeatBlob(Offset(size.width * 0.85, size.height * 0.3), 75, 0.28),
      _HeatBlob(Offset(size.width * 0.2, size.height * 0.2), 100, 0.12),
      _HeatBlob(Offset(size.width * 0.18, size.height * 0.18), 80, 0.1),
      _HeatBlob(Offset(size.width * 0.15, size.height * 0.25), 60, 0.08),
      _HeatBlob(Offset(size.width * 0.55, size.height * 0.7), 70, 0.25),
    ];

    for (final blob in blobs) {
      final paint = Paint()
        ..color = CozyTheme.peach.withOpacity(blob.intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
      canvas.drawCircle(blob.center, blob.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
