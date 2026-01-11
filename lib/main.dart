import 'package:flutter/material.dart';

import 'screens/map_screen.dart';
import 'state/showcase_state.dart';
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
  final ShowcaseState _showcaseState = ShowcaseState();

  @override
  void dispose() {
    _showcaseState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiet Route',
      theme: CozyTheme.build(),
      home: MapScreen(showcaseState: _showcaseState),
    );
  }
}
