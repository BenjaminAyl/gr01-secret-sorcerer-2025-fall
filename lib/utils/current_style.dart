import 'package:secret_sorcerer/models/user_model.dart';

/// Global style + identity cache for the *currently logged-in user*.
///
/// Stores:
///   - avatarColor
///   - hatColor
///   - nickname
///   - username
///
/// Load once after login:
///     CurrentStyle.loadFromUser(user);
///
/// Update after edits:
///     CurrentStyle.updateAvatar(...)
///     CurrentStyle.updateHat(...)
///     CurrentStyle.updateNickname(...)
///     CurrentStyle.updateUsername(...)
///
/// Access anywhere:
///     CurrentStyle.avatarColor
///     CurrentStyle.hatColor
///     CurrentStyle.nickname
///     CurrentStyle.username
///
class CurrentStyle {
  // ============================================================
  // Internal stored values (null means not initialized yet)
  // ============================================================
  static String? _avatarColor;
  static String? _hatColor;
  static String? _nickname;
  static String? _username;

  // ============================================================
  // Public Getters (with safe fallbacks)
  // ============================================================
  static String get avatarColor => _avatarColor ?? 'avatarDefault';
  static String get hatColor => _hatColor ?? 'hatDefault';

  static String get nickname => _nickname ?? '';
  static String get username => _username ?? '';

  /// Returns true when we know avatar + hat + nickname + username.
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

  // ============================================================
  // Combined Update
  // ============================================================
  static void update({
    String? avatar,
    String? hat,
    String? nickname,
    String? username,
  }) {
    if (avatar != null) _avatarColor = avatar;
    if (hat != null) _hatColor = hat;
    if (nickname != null) _nickname = nickname;
    if (username != null) _username = username;
  }

  // ============================================================
  // Reset (on logout)
  // ============================================================
  static void reset() {
    _avatarColor = null;
    _hatColor = null;
    _nickname = null;
    _username = null;
  }
}
