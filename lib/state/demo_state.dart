import 'package:flutter/foundation.dart';

import '../access_catalog.dart';
import '../privacy_phase.dart';

class DemoState extends ChangeNotifier {
  PrivacyPhase _currentPhase = PrivacyPhase.phase1;
  final Set<AccessItemId> _granted = {};
  int _routesPlanned = 0;
  bool _demoMode = true;

  PrivacyPhase get currentPhase => _currentPhase;
  Set<AccessItemId> get granted => _granted;
  int get routesPlanned => _routesPlanned;
  bool get demoMode => _demoMode;

  void toggleDemoMode(bool value) {
    _demoMode = value;
    notifyListeners();
  }

  void reset() {
    _currentPhase = PrivacyPhase.phase1;
    _granted.clear();
    _routesPlanned = 0;
    _demoMode = true;
    notifyListeners();
  }

  void registerRoutePlanned() {
    _routesPlanned += 1;
    notifyListeners();
  }

  AccessItem? nextRequest() {
    AccessItem? candidate = _nextInPhase();
    if (candidate != null) {
      return candidate;
    }
    if (_currentPhase.isMax) {
      return null;
    }
    _currentPhase = _currentPhase.next();
    candidate = _nextInPhase();
    notifyListeners();
    return candidate;
  }

  AccessItem? _nextInPhase() {
    final candidates = AccessCatalog.byPhase(_currentPhase)
        .where((item) => !_granted.contains(item.id))
        .toList();
    if (candidates.isEmpty) {
      return null;
    }
    return candidates.first;
  }

  void grant(AccessItemId id) {
    if (_granted.contains(id)) {
      return;
    }
    _granted.add(id);
    if (!_currentPhase.isMax) {
      _currentPhase = _currentPhase.next();
    }
    notifyListeners();
  }
}
