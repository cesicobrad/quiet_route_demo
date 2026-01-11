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
      _HeatBlob(Offset(size.width * 0.22, size.height * 0.32), 140, 0.14),
      _HeatBlob(Offset(size.width * 0.42, size.height * 0.48), 160, 0.18),
      _HeatBlob(Offset(size.width * 0.68, size.height * 0.4), 150, 0.16),
      _HeatBlob(Offset(size.width * 0.74, size.height * 0.62), 180, 0.2),
      _HeatBlob(Offset(size.width * 0.36, size.height * 0.72), 170, 0.17),
    ];

    for (final blob in blobs) {
      final intensity =
          (blob.intensity + (pulse * 0.08)).clamp(0.08, 0.32);
      final paint = Paint()
        ..color = CozyTheme.peach.withOpacity(intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
      canvas.drawCircle(blob.center, blob.radius, paint);
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

  const _HeatBlob(this.center, this.radius, this.intensity);
}
