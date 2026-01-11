import 'package:flutter/material.dart';

import 'screens/map_screen.dart';
import 'state/demo_state.dart';
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
  final DemoState _demoState = DemoState();

  @override
  void dispose() {
    _demoState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiet Route',
      theme: CozyTheme.build(),
      home: MapScreen(demoState: _demoState),
    );
  }
}
