import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class RouteProgressController {
  Timer? _timer;
  int _index = 0;

  void start({
    required List<LatLng> route,
    required Duration totalDuration,
    required ValueChanged<RouteProgress> onProgress,
  }) {
    stop();
    if (route.length < 2) {
      return;
    }
    final totalMs = max(totalDuration.inMilliseconds, 1);
    final stepMs = max(totalMs ~/ route.length, 240);
    _index = 0;
    _timer = Timer.periodic(Duration(milliseconds: stepMs), (_) {
      if (_index >= route.length) {
        stop();
        return;
      }
      onProgress(RouteProgress(index: _index, position: route[_index]));
      _index += 1;
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

class RouteProgress {
  final int index;
  final LatLng position;

  const RouteProgress({
    required this.index,
    required this.position,
  });
}
