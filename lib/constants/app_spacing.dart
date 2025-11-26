import 'package:flutter/material.dart';

/// Centralized spacing + padding system for consistent UI layout 🎯
class AppSpacing {
  // SizedBox gaps (vertical & horizontal)
  static const gapXS = SizedBox(height: 4);
  static const gapS = SizedBox(height: 8);
  static const gapM = SizedBox(height: 16);
  static const gapL = SizedBox(height: 24);
  static const gapXL = SizedBox(height: 32);
  static const gapXXL = SizedBox(height: 48);

  static const spaceL = SizedBox(height: 64);
  static const spaceXL = SizedBox(height: 128);
  static const spaceXXL = SizedBox(height: 200);

  static const gapWXS = SizedBox(width: 4);
  static const gapWS = SizedBox(width: 8);
  static const gapWM = SizedBox(width: 16);
  static const gapWL = SizedBox(width: 24);
  static const gapWXL = SizedBox(width: 32);

  // EdgeInsets padding
  static const screen = EdgeInsets.all(20);
  static const section = EdgeInsets.symmetric(vertical: 16);
  static const item = EdgeInsets.symmetric(vertical: 8, horizontal: 12);
  static const pillButton = EdgeInsets.symmetric(vertical: 8, horizontal: 16);

  // Specific themed uses
  static const titleSpacing = SizedBox(height: 32);
  static const buttonSpacing = SizedBox(height: 44);

  // Dimension Sizing
  static const double buttonHeightSmall = 44;
  static const double buttonHeightMedium = 56;
  static const double buttonHeightLarge = 80;

  static const double avatarSmall = 36;
  static const double avatarMedium = 56;
  static const double avatarLarge = 72;

  static const double cardWidthNarrow = 250;
  static const double cardWidthMedium = 320;
  static const double cardWidthWide = 400;
  static const double cardWidthLarge = 580;

  static const double iconSizeSmall = 20;
  static const double iconSizeMedium = 32;
  static const double iconSizeLarge = 48;

  static const double hatHeightLarge = 96;
  static const double hatWidthLarge = 96;

  // Radius sizing
  static const double radiusXS = 6;
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 24;

  // Themed radius use-cases
  static const double radiusButton = 35;
  static const double radiusCard = 20;
  static const double radiusAvatar = 32;
  static const double radiusSheet = 40;
}
