/// Original, kid-friendly fun facts for every letter and for a curated set of
/// numbers. Written in short, simple sentences a young child can understand.
abstract final class FunFacts {
  static const String fallback =
      'Learning something new every day is the best kind of magic!';

  static const Map<String, String> _letters = <String, String>{
    'A': 'Ants can carry things that are much heavier than themselves!',
    'B': 'Balls have been thrown and kicked for thousands of years.',
    'C': 'Cats can turn their ears to find where a sound comes from.',
    'D': 'Ducks have waterproof feathers that keep them dry in the rain.',
    'E': 'Elephants use their trunks like a hand to pick up food.',
    'F': 'Fish sleep with their eyes open because they have no eyelids.',
    'G': 'Giraffes have very long tongues to reach the highest leaves.',
    'H': 'Hats keep your head warm in winter and cool in summer.',
    'I': 'Ice cream comes in many flavors and colors all over the world.',
    'J': 'Juice is made by squeezing fruits to get their tasty liquid.',
    'K': 'Kites fly high when the wind pushes against them.',
    'L': 'Lions roar to talk with other lions far away.',
    'M': 'Mangoes are a sweet fruit that grows on big sunny trees.',
    'N': 'Birds build nests high in trees to keep their eggs safe.',
    'O': 'Oranges are packed with vitamin C that helps keep you healthy.',
    'P': 'Penguins waddle and slide on their bellies across the ice.',
    'Q': 'A queen leads her kingdom and wears a shiny crown.',
    'R': 'Rabbits have big ears that help them hear danger from far away.',
    'S': 'The Sun is a giant ball of hot gas that gives us light and warmth.',
    'T': 'No two tigers have the same stripes, just like your fingerprints!',
    'U': 'An umbrella is like a little roof that keeps the rain off you.',
    'V': 'Vans can carry lots of things, from toys to whole families.',
    'W': 'Watermelons are big, juicy fruits that are mostly water.',
    'X': 'A xylophone makes sound when you hit its colorful bars.',
    'Y': 'A yo-yo spins down and climbs right back up on its string.',
    'Z': 'Zebras have black and white stripes that help them blend in.',
  };

  static const Map<int, String> _numbers = <int, String>{
    1: 'The number one means "first", like the first place in a race.',
    2: 'You have two hands that can hold, clap, and wave hello.',
    3: 'Three is a storybook number, like the three little pigs.',
    4: 'A square has four sides, and a table usually has four legs.',
    5: 'You have five fingers on each hand, so you can count to five easily.',
    6: 'Bees and ants are six-legged insects — count their legs if you dare!',
    7: 'Seven is thought to be a lucky number in many places.',
    8: 'An octopus has eight wiggly arms for crawling and holding things.',
    9: 'In old stories a cat has nine lives — but really it just needs one!',
    10: 'Ten fingers and ten toes make ten a great number for counting.',
    11: 'Eleven is the first "teen" number and looks like two ones side by side.',
    12: 'There are twelve months in a year and twelve numbers on a clock.',
    13: 'Thirteen is called a "baker\'s dozen" — bakers used to give one extra!',
    14: 'The word "fourteen" has the number four hiding at its start.',
    15: 'Fifteen minutes is a quarter of an hour.',
    16: 'A sweet sixteen birthday is a big celebration in some places.',
    17: 'Seventeen is a prime number: only 1 and 17 divide it evenly.',
    18: 'Eighteen is double nine, and a tic-tac-toe grid has nine squares.',
    19: 'Nineteen is the very last number before the round twenty.',
    20: 'Twenty is how many fingers and toes you have together!',
    21: 'Twenty-one is one more than twenty — double ten plus one.',
    22: 'Twenty-two ducks paddling are two groups of eleven.',
    25: 'Twenty-five cents is a quarter of a dollar.',
    30: 'Thirty days have September — and thirty is five times six.',
    40: 'The word "forty" has its letters in alphabetical order: f, o, r, t, y!',
    50: 'Fifty is exactly halfway to one hundred.',
    60: 'Sixty seconds make one minute — count them while you wait!',
    70: 'Seventy is ten groups of seven.',
    80: 'Eighty is twenty times four.',
    90: 'Ninety is ten less than one hundred.',
    100: 'One hundred is ten groups of ten — a full century of years!',
  };

  static String forLetter(String letter) =>
      _letters[letter.toUpperCase()] ?? fallback;

  static String? forNumber(int number) => _numbers[number];
}