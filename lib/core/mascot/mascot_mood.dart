/// The moods the mascot ("Pip", a small round owl) can be in.
///
/// The set is deliberately small and always positive: a child is never shown a
/// sad or disappointed mascot, so a wrong answer maps to
/// [MascotMood.encouraging] rather than anything negative.
enum MascotMood {
  /// Calm breathing + blinking, no message.
  idle,

  /// Jump and smile — a letter/number was tapped or an answer was correct.
  happy,

  /// Wiggle, big eyes and sparkles — a star, badge or milestone was earned.
  excited,

  /// Soft head tilt and a warm smile — offered after a wrong answer.
  encouraging,
}

/// Kid-friendly one-liners the mascot says, one list per mood.
///
/// Plain data on purpose: the lists can be unit tested (size, wording, no
/// negative language) and are reused by both the speech bubble and the TTS
/// voice, so what a child reads is always exactly what they hear.
extension MascotMoodLines on MascotMood {
  List<String> get lines => switch (this) {
        MascotMood.idle => const <String>[
            'Hi! I am Pip. Tap a card to play!',
            'Ready to learn something fun?',
            'Tap any card to start!',
            'Let us learn together!',
            'Say hello to Pip!',
            'I am Pip, your learning pal!',
            'Tap me for a giggle!',
            'Learning is an adventure. Let us go!',
          ],
        MascotMood.happy => const <String>[
            'Great job!',
            'Awesome!',
            'You did it!',
            'That was wonderful!',
            'High five!',
            'Super star!',
            'Nice work!',
            'You are doing great!',
            'Bravo! Well done!',
            'I am so happy for you!',
          ],
        MascotMood.excited => const <String>[
            'Wow! That is amazing!',
            'Yay! You nailed it!',
            'Hooray! So clever!',
            'You are on fire!',
            'Woohoo! Star power!',
            'That is a mega star!',
            'Wowza! Fantastic!',
            'You are unstoppable!',
            'Wow! Look at you go!',
            'Boom! Perfect answer!',
          ],
        MascotMood.encouraging => const <String>[
            'Try again, you can do it!',
            'Almost there! Give it one more go!',
            'Not yet, but keep going!',
            'No problem, mistakes help us grow!',
            'Have another go, I believe in you!',
            'That one was tricky, try another!',
            'Oops! Let us try once more.',
            'Every try makes you better!',
            'Come on, you can do it!',
            'Keep going, you are learning!',
          ],
      };

  /// True for every mood that is a reaction to something the child just did.
  bool get isReaction => this != MascotMood.idle;
}

/// Playful squeaks said when the child taps the mascot itself.
const List<String> mascotGiggles = <String>[
  'Hee hee!',
  'That tickles!',
  'Hehe! Hello!',
  'Boop!',
  'Hee hee, that felt funny!',
  'Squeak!',
  'That tickles my feathers!',
  'Hee hee! Try me again!',
];
