enum AvatarColors {
  base,
  pink,
}

class AvatarColorData {
  final int requiredLevel;
  final String assetName;

  const AvatarColorData({
    required this.requiredLevel,
    required this.assetName,
  });
}

const Map<AvatarColors, AvatarColorData> avatarColorInfo = {
  AvatarColors.base: AvatarColorData(
    requiredLevel: 0,
    assetName: 'avatarDefault',
  ),
  AvatarColors.pink: AvatarColorData(
    requiredLevel: 5,
    assetName: 'avatarPink',
  ),
};



String avatarColorToString(AvatarColors avatarColor) {
  switch (avatarColor) {
    case AvatarColors.base:
      return 'avatarDefault';
    case AvatarColors.pink:
      return 'avatarPink';
  }
}