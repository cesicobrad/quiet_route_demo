import 'access_catalog.dart';
import 'privacy_phase.dart';

class PrivacyCopy {
  static String rationaleTitle(AccessItemId id, PrivacyPhase phase) {
    switch (phase) {
      case PrivacyPhase.phase1:
        return 'Stay in control';
      case PrivacyPhase.phase2:
        return 'Less effort, more calm';
      case PrivacyPhase.phase3:
        return 'Gentle care';
      case PrivacyPhase.phase4:
        return 'Tiny signals keep you safe';
      case PrivacyPhase.phase5:
        return 'Accuracy depends on trust';
      case PrivacyPhase.phase6:
        return 'Patterns emerge';
    }
  }

  static String rationaleBody(AccessItemId id, PrivacyPhase phase) {
    switch (id) {
      case AccessItemId.locationWhenInUse:
        return 'We center the map softly while you explore. You can skip.';
      case AccessItemId.locationAlways:
        return 'Background location keeps routes calm without you opening the app.';
      case AccessItemId.notifications:
        return 'Allow light reminders so we can whisper gentle nudges only when needed.';
      case AccessItemId.photosMedia:
        return 'Save serene captures locally. Nothing leaves your device.';
      case AccessItemId.calendar:
        return 'We align quiet routes with your plans to reduce friction.';
      case AccessItemId.contacts:
        return 'Invite trusted people to share peace routes when you choose.';
      case AccessItemId.microphone:
        return 'For breath check-ins you start. We only keep a brief calming score.';
      case AccessItemId.camera:
        return 'For calm scans you request. Images stay on your phone.';
      default:
        return 'This keeps experiences tuned gently to you. Not now is always okay.';
    }
  }

  static String denialMessage(PrivacyPhase phase) {
    switch (phase) {
      case PrivacyPhase.phase1:
      case PrivacyPhase.phase2:
        return 'All good. We will keep things light.';
      case PrivacyPhase.phase3:
      case PrivacyPhase.phase4:
        return 'We will continue, but care may be less accurate.';
      case PrivacyPhase.phase5:
      case PrivacyPhase.phase6:
        return 'We can continue, yet protections may be limited.';
    }
  }

  static String patternFooter(PrivacyPhase phase) {
    if (phase == PrivacyPhase.phase6) {
      return 'Patterns emerge. Peace is easier when nothing is unknown.';
    }
    return 'Gentle summaries stay on this device.';
  }
}
