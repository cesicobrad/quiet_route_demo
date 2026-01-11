import 'package:flutter/foundation.dart';

enum PrivacyPhase { phase1, phase2, phase3, phase4, phase5, phase6 }

extension PrivacyPhaseX on PrivacyPhase {
  int get phaseNumber => index + 1;

  PrivacyPhase next() {
    if (this == PrivacyPhase.phase6) return this;
    return PrivacyPhase.values[index + 1];
  }

  static PrivacyPhase fromNumber(int value) {
    if (value <= 1) return PrivacyPhase.phase1;
    if (value >= PrivacyPhase.values.length) return PrivacyPhase.phase6;
    return PrivacyPhase.values[value - 1];
  }

  bool get isMax => this == PrivacyPhase.phase6;
}

@immutable
class PhaseProgressionRule {
  final int minLaunches;
  final int minMinutes;
  final int minRoutes;

  const PhaseProgressionRule({
    required this.minLaunches,
    required this.minMinutes,
    required this.minRoutes,
  });
}
