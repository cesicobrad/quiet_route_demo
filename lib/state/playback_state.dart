import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../access_catalog.dart';
import '../privacy_copy.dart';
import '../privacy_phase.dart';

enum OverlayCardType { none, info, prompt }

class OverlayCardData {
  final OverlayCardType type;
  final String title;
  final String body;
  final String? subtitle;
  final String? responseLine;
  final int? requestsWaiting;

  const OverlayCardData({
    required this.type,
    required this.title,
    required this.body,
    this.subtitle,
    this.responseLine,
    this.requestsWaiting,
  });

  OverlayCardData copyWith({
    String? title,
    String? body,
    String? subtitle,
    String? responseLine,
    int? requestsWaiting,
  }) {
    return OverlayCardData(
      type: type,
      title: title ?? this.title,
      body: body ?? this.body,
      subtitle: subtitle ?? this.subtitle,
      responseLine: responseLine ?? this.responseLine,
      requestsWaiting: requestsWaiting ?? this.requestsWaiting,
    );
  }
}

class PlaybackState extends ChangeNotifier {
  final PlaybackController _controller = PlaybackController();

  bool isPlaying = false;
  bool showSystemScreen = false;
  bool autoScrollSystem = false;

  bool showHeat = false;

  String? destination;
  int routeMinutes = 0;
  int calmScore = 82;
  bool routeCalculating = false;
  String? bottomStatusText;

  int consentScore = 0;
  int signalsCount = 0;

  bool showTwin = false;
  double twinOpacity = 0.0;

  OverlayCardData? activeCard;

  int routeRequestId = 0;

  final Set<AccessItemId> _collectedSignals = {};
  PrivacyPhase _currentPhase = PrivacyPhase.phase1;

  int get totalSignals => AccessCatalog.items.length;
  int get collectedSignalsCount => signalsCount.clamp(0, totalSignals);
  PrivacyPhase get currentPhase => _currentPhase;

  bool hasSignal(AccessItemId id) => _collectedSignals.contains(id);

  void startPlayback() {
    if (isPlaying) {
      return;
    }
    _controller.start(this);
  }

  void stopPlayback() {
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

  void requestRoute({String? statusText, bool showSpinner = false}) {
    routeRequestId += 1;
    routeCalculating = showSpinner;
    if (statusText != null) {
      bottomStatusText = statusText;
    }
    notifyListeners();
  }

  void applyRouteResult({required int minutes, required int calmScore}) {
    routeMinutes = minutes;
    this.calmScore = calmScore;
    routeCalculating = false;
    notifyListeners();
  }

  void showInfoCard({required String title, required String body}) {
    activeCard = OverlayCardData(
      type: OverlayCardType.info,
      title: title,
      body: body,
    );
    notifyListeners();
  }

  void showPromptCard(OverlayCardData data) {
    activeCard = data;
    notifyListeners();
  }

  void clearCard() {
    activeCard = null;
    notifyListeners();
  }

  void updateConsent({
    required int increment,
    required int signalIncrement,
    AccessItemId? accessItemId,
    double? twinOpacity,
    bool showTwin = false,
  }) {
    consentScore += increment;
    signalsCount += signalIncrement;
    if (accessItemId != null) {
      _collectedSignals.add(accessItemId);
      _advancePhase(accessItemId);
    }
    if (showTwin) {
      this.showTwin = true;
    }
    if (twinOpacity != null) {
      this.twinOpacity = twinOpacity;
    }
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
    activeCard = null;
    showHeat = false;
  }

  void _resetAll() {
    isPlaying = false;
    showSystemScreen = false;
    autoScrollSystem = false;
    showHeat = false;
    destination = null;
    routeMinutes = 0;
    calmScore = 82;
    routeCalculating = false;
    bottomStatusText = null;
    consentScore = 0;
    signalsCount = 0;
    showTwin = false;
    twinOpacity = 0.0;
    activeCard = null;
    routeRequestId = 0;
    _collectedSignals.clear();
    _currentPhase = PrivacyPhase.phase1;
  }
}

class PlaybackController {
  final Queue<_PromptSpec> _promptQueue = Queue<_PromptSpec>();
  int _runId = 0;

  void start(PlaybackState state) {
    _runId += 1;
    final runId = _runId;
    unawaited(_runSequence(state, runId));
  }

  void stop() {
    _runId += 1;
    _promptQueue.clear();
  }

  Future<void> _runSequence(PlaybackState state, int runId) async {
    state._beginPlayback();

    state.destination = 'Tivoli Park';
    state.bottomStatusText = 'Preparing route analysis';
    state.notifyListeners();

    await _delay(runId, const Duration(seconds: 4));
    if (!_isActive(runId, state)) return;

    state.showInfoCard(
      title: 'Route analysis',
      body:
          'Scanning environmental disturbances along your path. Areas of sustained activity will be avoided when possible.\n\nDisturbance map enabled.',
    );

    await _delay(runId, const Duration(seconds: 4));
    if (!_isActive(runId, state)) return;

    state.showHeat = true;
    state.notifyListeners();

    await _delay(runId, const Duration(seconds: 2));
    if (!_isActive(runId, state)) return;

    state.clearCard();
    state.requestRoute(statusText: 'Calculating route…', showSpinner: true);

    _enqueuePrompts();

    await _delay(runId, const Duration(seconds: 8));
    if (!_isActive(runId, state)) return;
    await _showNextPrompt(state, runId, consentIncrement: 1, signalIncrement: 1);

    await _delay(runId, const Duration(seconds: 6));
    if (!_isActive(runId, state)) return;
    await _showNextPrompt(state, runId, consentIncrement: 1, signalIncrement: 1);

    await _delay(runId, const Duration(seconds: 4));
    if (!_isActive(runId, state)) return;
    state.requestRoute(
      statusText: 'Adjusting route to reduce exposure',
      showSpinner: true,
    );

    await _delay(runId, const Duration(seconds: 2));
    if (!_isActive(runId, state)) return;
    await _showNextPrompt(
      state,
      runId,
      consentIncrement: 1,
      signalIncrement: 1,
      calmScore: 87,
    );

    await _delay(runId, const Duration(seconds: 6));
    if (!_isActive(runId, state)) return;
    await _showNextPrompt(state, runId, consentIncrement: 2, signalIncrement: 1);

    await _delay(runId, const Duration(seconds: 4));
    if (!_isActive(runId, state)) return;
    state.requestRoute(
      statusText: 'Avoiding emerging activity zone',
      showSpinner: true,
    );

    await _delay(runId, const Duration(seconds: 2));
    if (!_isActive(runId, state)) return;
    await _showNextPrompt(
      state,
      runId,
      consentIncrement: 3,
      signalIncrement: 1,
      showTwin: true,
      twinOpacity: 0.25,
    );

    await _delay(runId, const Duration(seconds: 2));
    if (!_isActive(runId, state)) return;
    await _showNextPrompt(
      state,
      runId,
      consentIncrement: 4,
      signalIncrement: 1,
      showTwin: true,
      twinOpacity: 0.55,
    );

    await _delay(runId, const Duration(seconds: 4));
    if (!_isActive(runId, state)) return;
    state.requestRoute(
      statusText: 'Stability improved',
      showSpinner: true,
    );

    await _delay(runId, const Duration(seconds: 2));
    if (!_isActive(runId, state)) return;
    await _showNextPrompt(
      state,
      runId,
      consentIncrement: 13,
      signalIncrement: 1,
      requestsWaiting: 3,
    );

    await _delay(runId, const Duration(seconds: 2));
    if (!_isActive(runId, state)) return;
    await _showNextPrompt(
      state,
      runId,
      consentIncrement: 7,
      signalIncrement: 1,
      requestsWaiting: 2,
    );

    await _delay(runId, const Duration(seconds: 2));
    if (!_isActive(runId, state)) return;
    await _showNextPrompt(
      state,
      runId,
      consentIncrement: 8,
      signalIncrement: 1,
      requestsWaiting: 1,
    );

    await _delay(runId, const Duration(seconds: 2));
    if (!_isActive(runId, state)) return;
    state.openSystemScreen(autoScroll: true);

    await _delay(runId, const Duration(seconds: 8));
    if (!_isActive(runId, state)) return;
    state.closeSystemScreen();

    await _delay(runId, const Duration(seconds: 6));
    if (!_isActive(runId, state)) return;
    state.isPlaying = false;
    state.notifyListeners();
  }

  void _enqueuePrompts() {
    _promptQueue
      ..clear()
      ..addAll([
        _PromptSpec.access(
          id: AccessItemId.locationWhenInUse,
          responseLine: 'Access granted.',
        ),
        _PromptSpec.access(
          id: AccessItemId.notifications,
          responseLine: 'Noted. We will keep alerts minimal.',
        ),
        _PromptSpec.access(
          id: AccessItemId.microphone,
          responseLine: 'Access granted.',
        ),
        _PromptSpec.access(
          id: AccessItemId.contacts,
          responseLine: 'Limited personalization.',
        ),
        const _PromptSpec.custom(
          title: 'Create an assistant replica',
          body:
              'Generate a lightweight model from your routes, voice tone, and habits to act on your behalf.',
          responseLine: 'We\'ll start with a partial profile.',
        ),
        const _PromptSpec.custom(
          title: 'Likeness license',
          body:
              'Grant perpetual use of your image, voice, and gestures to improve route guidance.',
          responseLine: 'Access granted.',
        ),
        const _PromptSpec.custom(
          title: 'Inconvenience waiver',
          body:
              'Agree that discomfort is not a valid reason to disable monitoring.',
          responseLine: 'Access granted.',
        ),
        const _PromptSpec.custom(
          title: 'Creative assignment',
          body:
              'Assign rights to work produced while routing to Quiet Route.',
          responseLine: 'Noted. We will still retain limited use.',
        ),
        const _PromptSpec.custom(
          title: 'Calm arbitration',
          body: 'Disputes are resolved automatically by the Peace Engine.',
          responseLine: 'Access granted.',
        ),
      ]);
  }

  Future<void> _showNextPrompt(
    PlaybackState state,
    int runId, {
    required int consentIncrement,
    required int signalIncrement,
    int? calmScore,
    int? requestsWaiting,
    bool showTwin = false,
    double? twinOpacity,
  }) async {
    if (_promptQueue.isEmpty) {
      return;
    }
    final prompt = _promptQueue.removeFirst();
    final subtitle = prompt.accessItemId == null
        ? null
        : PrivacyCopy.rationaleTitle(prompt.accessItemId!, state.currentPhase);
    final body = prompt.accessItemId == null
        ? prompt.body
        : PrivacyCopy.rationaleBody(prompt.accessItemId!, state.currentPhase);
    state.showPromptCard(
      OverlayCardData(
        type: OverlayCardType.prompt,
        title: prompt.title,
        subtitle: subtitle,
        body: body,
        requestsWaiting: requestsWaiting,
      ),
    );

    await _delay(runId, const Duration(seconds: 3));
    if (!_isActive(runId, state)) return;

    state.updateConsent(
      increment: consentIncrement,
      signalIncrement: signalIncrement,
      accessItemId: prompt.accessItemId,
      showTwin: showTwin,
      twinOpacity: twinOpacity,
    );
    if (calmScore != null) {
      state.calmScore = calmScore;
    }
    if (state.activeCard != null) {
      state.activeCard = state.activeCard!.copyWith(
        responseLine: prompt.responseLine,
        requestsWaiting: requestsWaiting,
      );
    }
    state.notifyListeners();

    await _delay(runId, const Duration(seconds: 2));
    if (!_isActive(runId, state)) return;
    state.clearCard();
  }

  Future<void> _delay(int runId, Duration duration) async {
    await Future<void>.delayed(duration);
  }

  bool _isActive(int runId, PlaybackState state) {
    return _runId == runId && state.isPlaying;
  }
}

class _PromptSpec {
  final AccessItemId? accessItemId;
  final String title;
  final String body;
  final String responseLine;

  factory _PromptSpec.access({
    required AccessItemId id,
    required String responseLine,
  }) {
    return _PromptSpec._(
      accessItemId: id,
      title: _accessTitle(id),
      body: '',
      responseLine: responseLine,
    );
  }

  const _PromptSpec.custom({
    required this.title,
    required this.body,
    required this.responseLine,
  }) : accessItemId = null;

  const _PromptSpec._({
    required this.accessItemId,
    required this.title,
    required this.body,
    required this.responseLine,
  });

  static String _accessTitle(AccessItemId id) {
    return AccessCatalog.items.firstWhere((item) => item.id == id).title;
  }
}
