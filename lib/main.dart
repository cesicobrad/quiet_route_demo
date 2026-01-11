import 'package:flutter/material.dart';

import 'screens/map_screen.dart';
import 'state/playback_state.dart';
import 'theme/theme.dart';

void main() {
  runApp(const QuietRouteApp());
}

class QuietRouteApp extends StatefulWidget {
  const QuietRouteApp({super.key});

  @override
  State<QuietRouteApp> createState() => _QuietRouteAppState();
}

class _QuietRouteAppState extends State<QuietRouteApp> {
  final PlaybackState _playbackState = PlaybackState();

  @override
  void dispose() {
    _playbackState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiet Route',
      theme: CozyTheme.build(),
      home: MapScreen(playbackState: _playbackState),
    );
  }
}
