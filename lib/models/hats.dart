enum HatColors {
  base,
  blue,
  green,
  pink,
}


String hatColorToString(HatColors hatColor) {
  switch (hatColor) {
    case HatColors.base:
      return 'hatDefault';
    case HatColors.pink:
      return 'hatPink';
    case HatColors.blue:
      return 'hatBlue';
    case HatColors.green:
      return 'hatGreen';
  }
}