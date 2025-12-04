enum HatColors {
  base,
  blue,
  green,
  pink,
}

class HatColorData {
  final int requiredLevel;
  final String assetName;

  const HatColorData({
    required this.requiredLevel,
    required this.assetName,
  });
}

const Map<HatColors, HatColorData> hatColorInfo = {
  HatColors.base: HatColorData(
    requiredLevel: 0,
    assetName: 'hatDefault',
  ),
  HatColors.blue: HatColorData(
    requiredLevel: 3,
    assetName: 'hatBlue',
  ),
  HatColors.green: HatColorData(
    requiredLevel: 6,
    assetName: 'hatGreen',
  ),
  HatColors.pink: HatColorData(
    requiredLevel: 9,
    assetName: 'hatPink',
  ),
};



String hatColorToString(HatColors hatColor) {
  return hatColorInfo[hatColor]!.assetName;
}
