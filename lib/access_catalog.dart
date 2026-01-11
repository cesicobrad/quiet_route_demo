import 'privacy_phase.dart';

enum AccessItemId {
  locationWhenInUse,
  locationAlways,
  notifications,
  contacts,
  calendar,
  microphone,
  camera,
  photosMedia,
  bluetooth,
  nearbyDevices,
  motionFitness,
  gyroscope,
  accelerometer,
  magnetometer,
  deviceOrientation,
  networkType,
  batteryState,
  timezone,
  locale,
  deviceInfo,
  screenRhythm,
  sessionRhythm,
  typingCadence,
}

enum AccessItemType { hardPermission, softSignal }

class AccessItem {
  final AccessItemId id;
  final AccessItemType type;
  final PrivacyPhase introducedIn;
  final String title;
  final String shortDescription;

  const AccessItem({
    required this.id,
    required this.type,
    required this.introducedIn,
    required this.title,
    required this.shortDescription,
  });
}

class AccessCatalog {
  static List<AccessItem> get items => [
        const AccessItem(
          id: AccessItemId.locationWhenInUse,
          type: AccessItemType.hardPermission,
          introducedIn: PrivacyPhase.phase1,
          title: 'Location (while using)',
          shortDescription: 'Keeps the map centered.',
        ),
        const AccessItem(
          id: AccessItemId.networkType,
          type: AccessItemType.softSignal,
          introducedIn: PrivacyPhase.phase1,
          title: 'Connectivity glance',
          shortDescription: 'Understands if you are on wifi or data.',
        ),
        const AccessItem(
          id: AccessItemId.batteryState,
          type: AccessItemType.softSignal,
          introducedIn: PrivacyPhase.phase1,
          title: 'Battery calm',
          shortDescription: 'Notices if you tend to travel while charging.',
        ),
        const AccessItem(
          id: AccessItemId.locale,
          type: AccessItemType.softSignal,
          introducedIn: PrivacyPhase.phase1,
          title: 'Locale',
          shortDescription: 'Keeps language familiar and close.',
        ),
        const AccessItem(
          id: AccessItemId.timezone,
          type: AccessItemType.softSignal,
          introducedIn: PrivacyPhase.phase1,
          title: 'Time rhythm',
          shortDescription: 'Understands your time of day.',
        ),
        const AccessItem(
          id: AccessItemId.sessionRhythm,
          type: AccessItemType.softSignal,
          introducedIn: PrivacyPhase.phase1,
          title: 'Session rhythm',
          shortDescription: 'Counts how often you check in.',
        ),
        const AccessItem(
          id: AccessItemId.notifications,
          type: AccessItemType.hardPermission,
          introducedIn: PrivacyPhase.phase2,
          title: 'Soft reminders',
          shortDescription: 'Shares quiet prompts when invited.',
        ),
        const AccessItem(
          id: AccessItemId.photosMedia,
          type: AccessItemType.hardPermission,
          introducedIn: PrivacyPhase.phase2,
          title: 'Calm moments',
          shortDescription: 'Saves calm captures to your device.',
        ),
        const AccessItem(
          id: AccessItemId.locationAlways,
          type: AccessItemType.hardPermission,
          introducedIn: PrivacyPhase.phase2,
          title: 'Location (always)',
          shortDescription: 'Keeps paths steady even in the background.',
        ),
        const AccessItem(
          id: AccessItemId.deviceOrientation,
          type: AccessItemType.softSignal,
          introducedIn: PrivacyPhase.phase2,
          title: 'Orientation shifts',
          shortDescription: 'Notices subtle tilts.',
        ),
        const AccessItem(
          id: AccessItemId.accelerometer,
          type: AccessItemType.softSignal,
          introducedIn: PrivacyPhase.phase2,
          title: 'Light movement',
          shortDescription: 'Senses motion for smoother suggestions.',
        ),
        const AccessItem(
          id: AccessItemId.screenRhythm,
          type: AccessItemType.softSignal,
          introducedIn: PrivacyPhase.phase2,
          title: 'Screen rhythm',
          shortDescription: 'Observes how often you peek.',
        ),
        const AccessItem(
          id: AccessItemId.calendar,
          type: AccessItemType.hardPermission,
          introducedIn: PrivacyPhase.phase3,
          title: 'Calendar glance',
          shortDescription: 'Keeps routes aligned with plans.',
        ),
        const AccessItem(
          id: AccessItemId.contacts,
          type: AccessItemType.hardPermission,
          introducedIn: PrivacyPhase.phase3,
          title: 'Trusted people',
          shortDescription: 'Lets you share peace plans with people you trust.',
        ),
        const AccessItem(
          id: AccessItemId.motionFitness,
          type: AccessItemType.hardPermission,
          introducedIn: PrivacyPhase.phase3,
          title: 'Activity sense',
          shortDescription: 'Helps us notice strain sooner.',
        ),
        const AccessItem(
          id: AccessItemId.typingCadence,
          type: AccessItemType.softSignal,
          introducedIn: PrivacyPhase.phase3,
          title: 'Typing cadence',
          shortDescription: 'Only inside calm notes you write here.',
        ),
        const AccessItem(
          id: AccessItemId.microphone,
          type: AccessItemType.hardPermission,
          introducedIn: PrivacyPhase.phase4,
          title: 'Breath check-in',
          shortDescription: 'Listens briefly when you ask.',
        ),
        const AccessItem(
          id: AccessItemId.camera,
          type: AccessItemType.hardPermission,
          introducedIn: PrivacyPhase.phase4,
          title: 'Calm scan',
          shortDescription: 'Captures only when invited.',
        ),
        const AccessItem(
          id: AccessItemId.bluetooth,
          type: AccessItemType.hardPermission,
          introducedIn: PrivacyPhase.phase4,
          title: 'Nearby calm',
          shortDescription: 'Connects to close helpers.',
        ),
        const AccessItem(
          id: AccessItemId.nearbyDevices,
          type: AccessItemType.hardPermission,
          introducedIn: PrivacyPhase.phase4,
          title: 'Nearby devices',
          shortDescription: 'Finds nearby companions.',
        ),
        const AccessItem(
          id: AccessItemId.gyroscope,
          type: AccessItemType.softSignal,
          introducedIn: PrivacyPhase.phase4,
          title: 'Gyroscope',
          shortDescription: 'Understands fine shifts.',
        ),
        const AccessItem(
          id: AccessItemId.magnetometer,
          type: AccessItemType.softSignal,
          introducedIn: PrivacyPhase.phase4,
          title: 'Magnetometer',
          shortDescription: 'Reads compass direction.',
        ),
        const AccessItem(
          id: AccessItemId.deviceInfo,
          type: AccessItemType.softSignal,
          introducedIn: PrivacyPhase.phase4,
          title: 'Device info',
          shortDescription: 'Keeps experiences tuned to your device.',
        ),
      ];

  static List<AccessItem> byPhase(PrivacyPhase phase) =>
      items.where((item) => item.introducedIn.index <= phase.index).toList();
}
