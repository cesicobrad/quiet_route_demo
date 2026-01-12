import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/theme.dart';

class DisturbanceHeatOverlay extends StatefulWidget {
  final bool show;

  const DisturbanceHeatOverlay({
    super.key,
    required this.show,
  });

  @override
  State<DisturbanceHeatOverlay> createState() => _DisturbanceHeatOverlayState();
}

class _DisturbanceHeatOverlayState extends State<DisturbanceHeatOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: widget.show ? 1 : 0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _HeatPainter(pulse: _controller.value),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

class _HeatPainter extends CustomPainter {
  final double pulse;

  const _HeatPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final blobs = <_HeatBlob>[
      _HeatBlob(Offset(size.width * 0.18, size.height * 0.28), 120, 0.12, 0.8),
      _HeatBlob(Offset(size.width * 0.32, size.height * 0.42), 160, 0.18, 1.2),
      _HeatBlob(Offset(size.width * 0.46, size.height * 0.55), 140, 0.16, 1.5),
      _HeatBlob(Offset(size.width * 0.6, size.height * 0.36), 130, 0.14, 0.9),
      _HeatBlob(Offset(size.width * 0.7, size.height * 0.52), 170, 0.2, 1.1),
      _HeatBlob(Offset(size.width * 0.8, size.height * 0.68), 150, 0.17, 1.4),
      _HeatBlob(Offset(size.width * 0.52, size.height * 0.74), 180, 0.19, 0.7),
      _HeatBlob(Offset(size.width * 0.28, size.height * 0.66), 150, 0.16, 1.3),
      _HeatBlob(Offset(size.width * 0.12, size.height * 0.54), 120, 0.13, 1.6),
      _HeatBlob(Offset(size.width * 0.62, size.height * 0.22), 110, 0.12, 1.0),
    ];

    for (final blob in blobs) {
      final drift = Offset(
        sin((pulse * 2 * pi) + blob.phase) * 6,
        cos((pulse * 2 * pi) + blob.phase) * 6,
      );
      final intensity =
          (blob.intensity + (pulse * 0.08)).clamp(0.08, 0.3);
      final paint = Paint()
        ..color = CozyTheme.peach.withOpacity(intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
      canvas.drawCircle(blob.center + drift, blob.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeatPainter oldDelegate) {
    return oldDelegate.pulse != pulse;
  }
}

class _HeatBlob {
  final Offset center;
  final double radius;
  final double intensity;

  final double phase;

  const _HeatBlob(this.center, this.radius, this.intensity, this.phase);
}
