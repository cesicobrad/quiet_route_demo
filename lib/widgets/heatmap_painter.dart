import 'package:flutter/material.dart';

import '../theme/theme.dart';

class HeatmapPainter extends CustomPainter {
  final double pulse;
  final double intensityFactor;

  const HeatmapPainter({
    required this.pulse,
    required this.intensityFactor,
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
      final rawIntensity = blob.intensity + (pulse * 0.08);
      final intensity = (rawIntensity * intensityFactor).clamp(0.05, 0.5);
      final paint = Paint()
        ..color = CozyTheme.mint.withOpacity(intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
      canvas.drawCircle(blob.center, blob.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.intensityFactor != intensityFactor;
  }
}

class _HeatBlob {
  final Offset center;
  final double radius;
  final double intensity;

  const _HeatBlob(this.center, this.radius, this.intensity);
}
