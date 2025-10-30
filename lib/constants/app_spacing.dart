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

  // Specific themed uses
  static const titleSpacing = SizedBox(height: 32);
  static const buttonSpacing = SizedBox(height: 44);
}
