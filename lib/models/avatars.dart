enum AvatarColors {
  base,
  pink,
}


String avatarColorToString(AvatarColors avatarColor) {
  switch (avatarColor) {
    case AvatarColors.base:
      return 'avatarDefault';
    case AvatarColors.pink:
      return 'avatarPink';
  }
}