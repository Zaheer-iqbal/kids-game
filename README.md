# kids

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Motion system

All animation goes through `lib/core/motion/app_motion.dart` — the single place
that hand-rolls curves:

- `MotionStyle` / `MotionPresets` — the app's whole motion vocabulary
  (`fadeInUp`, `bounceIn`, `tada`, `jello`, `headShake`, `pulse`, `heartBeat`,
  `wobble`, `zoomIn`, `zoomOut`, `rubberBand`, …).
- `AppMotion` — wraps one child and plays a named style. It owns a controller,
  or borrows a shared one from an ancestor `MotionStagger`.
- `MotionStagger` — one ticker for a whole list/grid, with each `AppMotion`
  claiming a slice via `index`, so a screen never pays for per-item tickers.
- `reduceMotion` — the "Reduce motion" switch or the OS flag degrades motion to
  a short fade (or nothing for looping styles); one-shot styles are pinned to
  their finished frame.

This is intentionally **in-house rather than `flutter_easy_animations`**: that
package requires Flutter 3.47 / Dart 3.13, while this project is pinned to
Flutter 3.35 / Dart 3.9. The helper exposes the same effect names so we can
switch to the package later without touching call sites.

## Voice & narration

Every sound the app makes goes through the single `AudioService`
(`lib/core/services/audio_service.dart`) — chimes are synthesized in memory and
narration prefers a recorded clip before falling back to the device voice.

Priority order for a spoken line:

1. **Recorded clip** — `assets/audio/voice/<key>.mp3`, where `<key>` is built by
   `VoiceClips` (`letter_a`, `number_27`, `animal_lion`, …). See
   `assets/audio/voice/README.md` for the naming table and recording tips.
2. **Device voice** — `flutter_tts`, tuned for young listeners: `en-US`, slow
   rate (default `0.45`, adjustable), `pitch 1.15`, one utterance per tap.

At startup the service asks the engine for its voices, auto-picks the best
local English voice, and remembers a parent's pick. The "Voice & speed" card in
Grown-up Settings is hidden behind the hold-to-open parental gate; it lets a
parent choose the voice, set the speed and press **Test voice**.

Generate clips with any TTS tool (or a real voice actor), export mono 44.1 kHz
MP3, and drop them into `assets/audio/voice/` — no code change needed.
