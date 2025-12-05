enum AvatarStyles { 
  base, 
  moustache, 
  eyes,
  liam,  
  frog, 
  }

class AvatarStyleData {
  final int requiredLevel;
  final String assetName;

  const AvatarStyleData({required this.requiredLevel, required this.assetName});
}

const Map<AvatarStyles, AvatarStyleData> avatarStyleInfo = {
  AvatarStyles.base: AvatarStyleData(requiredLevel: 0, assetName: 'avatarDefault'),
  AvatarStyles.moustache: AvatarStyleData(requiredLevel: 2, assetName: 'avatarMoustache'),
  AvatarStyles.eyes: AvatarStyleData(requiredLevel: 3, assetName: 'avatarEyes'),
  AvatarStyles.liam: AvatarStyleData(requiredLevel: 4, assetName: 'avatarLiam'),
  AvatarStyles.frog: AvatarStyleData(requiredLevel: 5, assetName: 'avatarFrog'),
};

String avatarColorToString(AvatarStyles avatarStyle) {
  switch (avatarStyle) {
    case AvatarStyles.base:
      return 'avatarDefault';
    case AvatarStyles.moustache:
      return 'avatarMoustache';
    case AvatarStyles.eyes:
      return 'avatarEyes';
    case AvatarStyles.liam:
      return 'avatarLiam';
    case AvatarStyles.frog:
      return 'avatarFrog';
  }
}
