import 'dart:io' show Platform;

/// True when running under `flutter test` (the flutter tool exports this env
/// var to the test process). VM-only — kept out of the web build via the
/// conditional import in audio_service.dart.
bool get isFlutterTest => Platform.environment.containsKey('FLUTTER_TEST');