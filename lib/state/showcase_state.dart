import 'dart:async';

import 'package:flutter/foundation.dart';

import '../access_catalog.dart';
import '../privacy_copy.dart';
import '../privacy_phase.dart';

class PromptCardData {
  final String title;
  final String? subtitle;
  final String body;
  final AccessItemId? accessItemId;

  const PromptCardData({
    required this.title,
    required this.body,
    this.subtitle,
    this.accessItemId,
  });
}

class ShowcaseState extends ChangeNotifier {
  final ShowcaseController _controller = ShowcaseController();

  bool isPlaying = false;
  bool showSystemScreen = false;
  bool autoScrollSystem = false;

  String? destination;
  bool isCalculating = false;
  int routeMinutes = 0;
  int calmScore = 82;

  int consentCount = 0;
  int queueCount = 0;
  bool showQueueIndicator = false;

  PromptCardData? activePrompt;
  String? promptResponse;
  bool promptResolved = false;

  bool showTwin = false;
  double twinOpacity = 0.0;

  final Set<AccessItemId> _collectedSignals = {};

  int _destinationRequestToken = 0;
  String? _pendingDestination;

  PrivacyPhase _currentPhase = PrivacyPhase.phase1;

  int get destinationRequestToken => _destinationRequestToken;
  String? get pendingDestination => _pendingDestination;

  int get collectedSignalsCount => _collectedSignals.length;
  int get totalSignals => AccessCatalog.items.length;

  bool hasSignal(AccessItemId id) => _collectedSignals.contains(id);

  double get heatmapIntensity {
    final factor = 1.0 + (consentCount / 40) * 0.35;
    return factor.clamp(1.0, 1.35);
  }

  PrivacyPhase get currentPhase => _currentPhase;

  void startShowcase() {
    if (isPlaying) {
      return;
    }
    _controller.start(this);
  }

  void stopShowcase() {
    if (!isPlaying) {
      return;
    }
    _controller.stop();
    _resetPlaybackFlags();
    notifyListeners();
  }

  void reset() {
    _controller.stop();
    _resetAll();
    notifyListeners();
  }

  void requestDestination(String destination) {
    _pendingDestination = destination;
    _destinationRequestToken += 1;
    notifyListeners();
  }

  void consumeDestinationRequest() {
    _pendingDestination = null;
  }

  Future<void> startRouteCalculation({
    required String destination,
    required int minutes,
    required int calmScore,
  }) async {
    this.destination = destination;
    isCalculating = true;
    routeMinutes = 0;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 1200));

    isCalculating = false;
    routeMinutes = minutes;
    this.calmScore = calmScore;
    notifyListeners();
  }

  void updateCalmScore(int value) {
    calmScore = value;
    notifyListeners();
  }

  void showPrompt(
    PromptCardData prompt, {
    bool showQueueIndicator = false,
    int queueCount = 0,
  }) {
    activePrompt = prompt;
    promptResponse = null;
    promptResolved = false;
    this.showQueueIndicator = showQueueIndicator;
    this.queueCount = queueCount;
    notifyListeners();
  }

  void resolvePrompt({
    required bool accepted,
    String? responseLine,
    int? consentValue,
    int? queueCount,
    int? calmScore,
    AccessItemId? accessItemId,
    bool assumeSignal = false,
    bool showTwin = false,
    double? twinOpacity,
  }) {
    promptResponse = responseLine;
    promptResolved = true;
    if (consentValue != null) {
      consentCount = consentValue;
    }
    if (queueCount != null) {
      this.queueCount = queueCount;
    }
    if (calmScore != null) {
      this.calmScore = calmScore;
    }
    if (showTwin) {
      this.showTwin = true;
    }
    if (twinOpacity != null) {
      this.twinOpacity = twinOpacity;
    }
    if (accessItemId != null && (accepted || assumeSignal)) {
      _collectedSignals.add(accessItemId);
      _advancePhase(accessItemId);
    }
    notifyListeners();
  }

  void clearPrompt() {
    activePrompt = null;
    promptResponse = null;
    promptResolved = false;
    showQueueIndicator = false;
    notifyListeners();
  }

  void openSystemScreen({bool autoScroll = false}) {
    showSystemScreen = true;
    autoScrollSystem = autoScroll;
    notifyListeners();
  }

  void closeSystemScreen() {
    showSystemScreen = false;
    autoScrollSystem = false;
    notifyListeners();
  }

  void _advancePhase(AccessItemId id) {
    final newPhase = AccessCatalog.items
        .firstWhere((item) => item.id == id)
        .introducedIn;
    if (newPhase.index > _currentPhase.index) {
      _currentPhase = newPhase;
    }
  }

  void _beginPlayback() {
    _resetAll();
    isPlaying = true;
    notifyListeners();
  }

  void _resetPlaybackFlags() {
    isPlaying = false;
    showSystemScreen = false;
    autoScrollSystem = false;
    activePrompt = null;
    promptResponse = null;
    promptResolved = false;
    showQueueIndicator = false;
  }

  void _resetAll() {
    isPlaying = false;
    showSystemScreen = false;
    autoScrollSystem = false;
    destination = null;
    isCalculating = false;
    routeMinutes = 0;
    calmScore = 82;
    consentCount = 0;
    queueCount = 0;
    showQueueIndicator = false;
    activePrompt = null;
    promptResponse = null;
    promptResolved = false;
    showTwin = false;
    twinOpacity = 0.0;
    _collectedSignals.clear();
    _pendingDestination = null;
    _destinationRequestToken = 0;
    _currentPhase = PrivacyPhase.phase1;
  }
}

class ShowcaseController {
  int _runId = 0;

  void start(ShowcaseState state) {
    _runId += 1;
    final runId = _runId;
    unawaited(_runSequence(state, runId));
  }

  void stop() {
    _runId += 1;
  }

  Future<void> _runSequence(ShowcaseState state, int runId) async {
    state._beginPlayback();

    await _delay(runId, const Duration(seconds: 8));
    if (!_isActive(runId, state)) return;
    state.requestDestination('Tivoli Park');

    await _delay(runId, const Duration(seconds: 12));
    if (!_isActive(runId, state)) return;
    await _promptAccess(
      state,
      runId,
      id: AccessItemId.locationWhenInUse,
      consentValue: 1,
      accepted: true,
      readDuration: const Duration(seconds: 3),
      responseLine: 'Access granted.',
    );

    await _delay(runId, const Duration(seconds: 4));
    if (!_isActive(runId, state)) return;
    await _promptAccess(
      state,
      runId,
      id: AccessItemId.notifications,
      consentValue: 2,
      accepted: false,
      assumeSignal: true,
      readDuration: const Duration(seconds: 3),
      responseLine: 'Noted. We will keep alerts minimal.',
    );

    await _delay(runId, const Duration(seconds: 4));
    if (!_isActive(runId, state)) return;
    await _promptAccess(
      state,
      runId,
      id: AccessItemId.microphone,
      consentValue: 3,
      accepted: true,
      readDuration: const Duration(seconds: 3),
      responseLine: 'Access granted.',
      calmScore: 87,
    );

    await _delay(runId, const Duration(seconds: 4));
    if (!_isActive(runId, state)) return;
    await _promptAccess(
      state,
      runId,
      id: AccessItemId.contacts,
      consentValue: 5,
      accepted: false,
      assumeSignal: true,
      readDuration: const Duration(seconds: 3),
      responseLine: 'Limited personalization.',
    );

    await _delay(runId, const Duration(seconds: 4));
    if (!_isActive(runId, state)) return;
    await _promptCustom(
      state,
      runId,
      PromptCardData(
        title: 'Create an assistant replica',
        body:
            'Generate a lightweight model from your routes, voice tone, and habits to act on your behalf.',
      ),
      consentValue: 8,
      accepted: false,
      readDuration: const Duration(seconds: 3),
      responseLine: 'We\'ll start with a partial profile.',
      showTwin: true,
      twinOpacity: 0.25,
    );

    await _delay(runId, const Duration(seconds: 2));
    if (!_isActive(runId, state)) return;
    await _promptCustom(
      state,
      runId,
      PromptCardData(
        title: 'Likeness license',
        body:
            'Grant perpetual use of your image, voice, and gestures to improve route guidance.',
      ),
      consentValue: 12,
      accepted: true,
      readDuration: const Duration(seconds: 3),
      responseLine: 'Access granted.',
      showTwin: true,
      twinOpacity: 0.55,
    );

    await _delay(runId, const Duration(seconds: 4));
    if (!_isActive(runId, state)) return;
    await _promptBurst(state, runId);

    await _delay(runId, const Duration(seconds: 2));
    if (!_isActive(runId, state)) return;
    state.openSystemScreen(autoScroll: true);

    await _delay(runId, const Duration(seconds: 10));
    if (!_isActive(runId, state)) return;
    state.closeSystemScreen();

    await _delay(runId, const Duration(seconds: 6));
    if (!_isActive(runId, state)) return;
    state.isPlaying = false;
    state.notifyListeners();
  }

  Future<void> _promptAccess(
    ShowcaseState state,
    int runId, {
    required AccessItemId id,
    required int consentValue,
    required bool accepted,
    required Duration readDuration,
    required String responseLine,
    bool assumeSignal = false,
    int? calmScore,
  }) async {
    final item = AccessCatalog.items.firstWhere((item) => item.id == id);
    final title = PrivacyCopy.rationaleTitle(id, state.currentPhase);
    final body = PrivacyCopy.rationaleBody(id, state.currentPhase);
    state.showPrompt(
      PromptCardData(
        title: item.title,
        subtitle: title,
        body: body,
        accessItemId: id,
      ),
    );

    await _delay(runId, readDuration);
    if (!_isActive(runId, state)) return;
    state.resolvePrompt(
      accepted: accepted,
      consentValue: consentValue,
      responseLine: responseLine,
      accessItemId: id,
      assumeSignal: assumeSignal,
      calmScore: calmScore,
    );

    await _delay(runId, const Duration(seconds: 2));
    if (!_isActive(runId, state)) return;
    state.clearPrompt();
  }

  Future<void> _promptCustom(
    ShowcaseState state,
    int runId,
    PromptCardData prompt, {
    required int consentValue,
    required bool accepted,
    required Duration readDuration,
    required String responseLine,
    bool showTwin = false,
    double? twinOpacity,
  }) async {
    state.showPrompt(prompt);
    await _delay(runId, readDuration);
    if (!_isActive(runId, state)) return;
    state.resolvePrompt(
      accepted: accepted,
      consentValue: consentValue,
      responseLine: responseLine,
      showTwin: showTwin,
      twinOpacity: twinOpacity,
    );
    await _delay(runId, const Duration(seconds: 2));
    if (!_isActive(runId, state)) return;
    state.clearPrompt();
  }

  Future<void> _promptBurst(ShowcaseState state, int runId) async {
    state.showPrompt(
      const PromptCardData(
        title: 'Inconvenience waiver',
        body:
            'Agree that discomfort is not a valid reason to disable monitoring.',
      ),
      showQueueIndicator: true,
      queueCount: 3,
    );
    await _delay(runId, const Duration(seconds: 2));
    if (!_isActive(runId, state)) return;
    state.resolvePrompt(
      accepted: true,
      consentValue: 25,
      responseLine: 'Access granted.',
      queueCount: 2,
    );
    await _delay(runId, const Duration(seconds: 1));
    if (!_isActive(runId, state)) return;
    state.clearPrompt();

    state.showPrompt(
      const PromptCardData(
        title: 'Creative assignment',
        body:
            'Assign rights to work produced while routing to Quiet Route.',
      ),
      showQueueIndicator: true,
      queueCount: 2,
    );
    await _delay(runId, const Duration(seconds: 2));
    if (!_isActive(runId, state)) return;
    state.resolvePrompt(
      accepted: false,
      consentValue: 32,
      responseLine: 'Noted. We will still retain limited use.',
      queueCount: 1,
    );
    await _delay(runId, const Duration(seconds: 1));
    if (!_isActive(runId, state)) return;
    state.clearPrompt();

    state.showPrompt(
      const PromptCardData(
        title: 'Calm arbitration',
        body: 'Disputes are resolved automatically by the Peace Engine.',
      ),
      showQueueIndicator: true,
      queueCount: 1,
    );
    await _delay(runId, const Duration(seconds: 2));
    if (!_isActive(runId, state)) return;
    state.resolvePrompt(
      accepted: true,
      consentValue: 40,
      responseLine: 'Access granted.',
      queueCount: 0,
    );
    await _delay(runId, const Duration(seconds: 1));
    if (!_isActive(runId, state)) return;
    state.clearPrompt();
  }

  Future<void> _delay(int runId, Duration duration) async {
    await Future<void>.delayed(duration);
  }

  bool _isActive(int runId, ShowcaseState state) {
    return _runId == runId && state.isPlaying;
  }
}
