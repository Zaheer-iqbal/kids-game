# Recorded voice clips (optional)

Drop studio-recorded MP3s here to replace the on-device text-to-speech voice
for the things they name. Any missing clip simply falls back to the device
voice, so this folder may stay empty and the app still narrates everything.

Naming (see `VoiceClips` in `lib/core/services/audio_service.dart`):

| Clip                 | Says                              |
| -------------------- | --------------------------------- |
| `letter_a.mp3`       | the letter "A" / "A. Apple."      |
| `number_27.mp3`      | "twenty seven"                    |
| `animal_lion.mp3`    | the lion's name + fact            |

Guidelines

- Mono, 44.1 kHz, ~96 kbps MP3 keeps the app small.
- Trim silence at both ends; no fade-in on the very first word.
- Keep a warm, unhurried pace — around 120–140 words per minute.
- Speak numbers as words ("twenty seven"), never as digits.
