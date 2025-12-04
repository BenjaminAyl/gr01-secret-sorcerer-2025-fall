import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/models/user_model.dart';

CollectionReference usersDB = FirebaseFirestore.instance.collection("users");

final firebaseController = FirebaseController();

class UserAuth {

  /// Safely decodes a Firestore [DocumentSnapshot] into a [Map] of data.
  ///
  /// Returns an empty map if no data exists.
  ///
  /// [snap] — The Firestore document to decode.
  Map<String, dynamic> decodeSnapshot(DocumentSnapshot snap) {
    return (snap.data() as Map<String, dynamic>?) ?? {};
  }

  // Returns information about the current user from FirebaseAuth + Firestore.
  // If no user is signed in, returns null.
  Future<AppUser?> getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // Load profile from Firestore and normalize field names for AppUser.
    final snap = await usersDB.doc(user.uid).get();
    final data = decodeSnapshot(snap);

    return AppUser.fromMap({
      'uid': user.uid,
      'email': user.email ?? data['Email'] ?? data['email'] ?? '',
      'username': (data['Username'] ?? data['username'] ?? '').toString().toLowerCase(),
      'nickname': data['Nickname'] ?? data['nickname'] ?? '',
      'hatColor': data['HatColor'] ?? data['hatColor'] ?? 'hatDefault',
      'avatarColor': data['avatarColor'] ?? data['avatarColor'] ?? 'avatarDefault',
      'exp': data['exp'] ?? data['exp'] ?? 0,
      'currentLevel': data['currentLevel'] ?? data['currentLevel'] ?? 0
    });
  }

  /// Returns true if [username] (case-insensitive) is not taken.
  Future<bool> isUsernameAvailable(String username) async {
    final candidate = username.trim().toLowerCase();
    if (candidate.isEmpty) return false;

    final result = await usersDB
        .where('Username', isEqualTo: candidate)
        .limit(1)
        .get();

    return result.docs.isEmpty; // true if no user has that username
  }

  /// Creates a new Firebase user and stores their profile in Firestore.
  ///
  /// [email] — The user's email address.
  /// [password] — The user's chosen password.
  /// [username] — The desired username for display or lookup.
  /// [nickname] — A secondary display name or alias.
  ///
  /// Throws a [FirebaseAuthException] if authentication fails.
  Future<String> signUp({
    required String email,
    required String password,
    required String username,
    required String nickname,
  }) async {
    // Create Firebase Auth user
    final credential = await firebaseController.signUp(email, password);
    final uid = credential.user!.uid;

    // Normalize username to lowercase
    final usernameLower = username.trim().toLowerCase();

    usersDB.doc(uid).set({
      "UID": uid,
      "Username": usernameLower,
      "Email": credential.user!.email,
      "Nickname": nickname,
      "wins": 0,
      "losses": 0,
      "hatColor": "hatDefault",
      "avatar": "avatarDefault",
      "currentLevel": 1,
      "exp": 0,
    });

    return uid;
  }

  /// Signs in an existing user and saves their session locally with Hive.
  ///
  /// [email] — The user's registered email address.
  /// [password] — The user's account password.
  ///
  /// Returns a [UserCredential] object containing Firebase user info.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    // Authenticate with Firebase Auth. Session state is managed by Firebase.
    final userCredit = await firebaseController.signIn(email, password);
    return userCredit;
  }

  /// Signs the user out and clears session data.
  Future<void> signOut() async {
  // Sign out from Firebase Auth
  await FirebaseAuth.instance.signOut();
}

  /// Updates the user's username in Firestore.
  ///
  /// [newUsername] — The new username to set.
  /// [oldUsername] — The current username before the update.
  ///
  /// TODO: Implement username change logic.
  Future<void> changeUsername({
    required String newUsername,
    required String oldUsername,
  }) async {
    final bool check = await isUsernameAvailable(newUsername);
    if (check) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await usersDB.doc(user.uid).update({
        "Username": newUsername,
      });
    } else {
      throw Exception("Username is already taken");
    }
  }

  /// Deletes the user's account and associated data.
  ///
  /// TODO: Implement delete account logic.
  Future<void> deleteAccount() async {
    // TODO: implement delete account logic
  }

  static Future<void> updateNickname(String newNickname) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await usersDB.doc(user.uid).update({
      "Nickname": newNickname,
    });
  }
}
