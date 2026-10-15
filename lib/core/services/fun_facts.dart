/// Original, kid-friendly fun facts for every letter and for a curated set of
/// numbers. Written in short, simple sentences a young child can understand.
abstract final class FunFacts {
  static const String fallback =
      'Learning something new every day is the best kind of magic!';

  static const Map<String, String> _letters = <String, String>{
    'A': 'Ants can lift things 50 times heavier than their own body!',
    'B': 'Bears can smell food from over 20 miles away — a super nose!',
    'C': 'Cats spend about 70% of their lives sleeping — lucky them!',
    'D': 'Dogs can hear sounds four times farther away than humans can.',
    'E': 'Elephants are the only animals that cannot jump!',
    'F': 'Fish sleep with their eyes open because they have no eyelids.',
    'G': 'Goats have rectangular pupils that help them see almost all around.',
    'H': 'Horses can sleep standing up so they can run from danger fast.',
    'I': 'Iguanas can hold their breath underwater for up to 30 minutes!',
    'J': 'Jaguars are excellent swimmers and love to hunt near rivers.',
    'K': 'Koalas sleep up to 22 hours a day — they are very sleepy animals!',
    'L': 'Lions roar to talk with other lions who are far away.',
    'M': 'Monkeys peel bananas from the bottom, just like people do!',
    'N': 'Narwhals have a long spiral tusk that can grow up to 10 feet long!',
    'O': 'Owls can turn their heads almost all the way around!',
    'P': 'Parrots can learn to say hundreds of human words!',
    'Q': 'Quails are tiny birds that run very fast along the ground.',
    'R': 'Rabbits have big ears that help them hear danger from far away.',
    'S': 'Snakes have no legs but can swim, climb trees, and move very fast.',
    'T': 'No two tigers have the same stripes, just like your fingerprints!',
    'U': 'Unicorns appear in stories from ancient Scotland and China!',
    'V': 'Vultures have a stomach so strong it can digest old bones.',
    'W': 'Wolves howl at night to talk to the other wolves in their pack.',
    'X': 'Xerus are African ground squirrels that use their tails as sunshades!',
    'Y': 'Yaks have very thick fur to stay warm on snowy mountains.',
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