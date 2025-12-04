import 'package:secret_sorcerer/models/user_model.dart';

/// Global style + identity cache for the *currently logged-in user*.
///
/// Stores:
///   - avatarColor
///   - hatColor
///   - nickname
///   - username
///   - currentLevel
///   - currentExp (0–100)
///
class CurrentStyle {
  // ============================================================
  // Internal stored values (null means not initialized yet)
  // ============================================================
  static String? _avatarColor;
  static String? _hatColor;
  static String? _nickname;
  static String? _username;

  static int? _currentLevel;  // user’s current level
  static int? _currentExp; // 0–100 xp percentage

  // ============================================================
  // Public Getters (with safe fallbacks)
  // ============================================================
  static String get avatarColor => _avatarColor ?? 'avatarDefault';
  static String get hatColor => _hatColor ?? 'hatDefault';

  static String get nickname => _nickname ?? '';
  static String get username => _username ?? '';

  static int get currentLevel => _currentLevel ?? 1;      // default level 1
  static int get currentExp => _currentExp ?? 0;     // default 0%

  /// Returns true when core style values are loaded.
  static bool get isLoaded =>
      _avatarColor != null &&
      _hatColor != null &&
      _nickname != null &&
      _username != null;

  // ============================================================
  // Initial Load (after login)
  // ============================================================
  static void loadFromUser(AppUser? user) {
    _avatarColor = user?.avatarColor ?? 'avatarDefault';
    _hatColor = user?.hatColor ?? 'hatDefault';
    _nickname = user?.nickname ?? '';
    _username = user?.username ?? '';

    _currentLevel = user?.currentLevel ?? 1;
    _currentExp = user?.exp ?? 0;
  }

  // ============================================================
  // Individual Updates
  // ============================================================
  static void updateAvatar(String newAvatar) {
    _avatarColor = newAvatar;
  }

  static void updateHat(String newHat) {
    _hatColor = newHat;
  }

  static void updateNickname(String newName) {
    _nickname = newName;
  }

  static void updateUsername(String newUsername) {
    _username = newUsername;
  }

  static void updateLevel(int newLevel) {
    _currentLevel = newLevel;
  }

  static void updateExp(int newExp) {
    // force clamp to 0–100 range
    _currentExp = newExp.clamp(0, 100);
  }

  // ============================================================
  // Combined Update
  // ============================================================
  static void update({
    String? avatar,
    String? hat,
    String? nickname,
    String? username,
    int? level,
    int? exp,
  }) {
    if (avatar != null) _avatarColor = avatar;
    if (hat != null) _hatColor = hat;
    if (nickname != null) _nickname = nickname;
    if (username != null) _username = username;

    if (level != null) _currentLevel = level;
    if (exp != null) _currentExp = exp.clamp(0, 100);
  }

  // ============================================================
  // Reset (on logout)
  // ============================================================
  static void reset() {
    _avatarColor = null;
    _hatColor = null;
    _nickname = null;
    _username = null;

    _currentLevel = null;
    _currentExp = null;
  }
}