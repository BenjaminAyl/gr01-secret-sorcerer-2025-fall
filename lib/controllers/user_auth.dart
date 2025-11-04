import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:secret_sorcerer/models/user_model.dart';

CollectionReference usersDB = FirebaseFirestore.instance.collection("users");

final firebaseController = FirebaseController();

class UserAuth {
  static const _sessionBox = 'session';
  static const _userKey = 'user';

  /// Safely decodes a Firestore [DocumentSnapshot] into a [Map] of data.
  ///
  /// Returns an empty map if no data exists.
  ///
  /// [snap] — The Firestore document to decode.
  Map<String, dynamic> decodeSnapshot(DocumentSnapshot snap) {
    return (snap.data() as Map<String, dynamic>?) ?? {};
  }

  /// Opens or returns the Hive box used for storing user session data.
  ///
  /// Returns a [Box] that contains session info.
  Future<Box> _openSessionBox() async {
    if (!Hive.isBoxOpen(_sessionBox)) {
      await Hive.openBox(_sessionBox);
    }
    return Hive.box(_sessionBox);
  }

  // Returns information about the current user
  Future<AppUser?> getCurrentUser() async {
    final box = await Hive.openBox(_sessionBox);
    final data = box.get(_userKey);
    if (data == null) return null;
    return AppUser.fromMap(Map<String, dynamic>.from(data));
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
    final userCredit = await firebaseController.signIn(email, password);

    // Load profile from Firestore.
    final currentUid = userCredit.user!.uid;
    final snap = await usersDB.doc(currentUid).get();
    final userData = decodeSnapshot(snap);

    // Save minimal session data locally.
    final box = await _openSessionBox();
    await box.put(_userKey, {
      'uid': currentUid,
      'email': userCredit.user!.email,
      'username': userData['Username'],
      'nickname': userData['Nickname'],
    });

    return userCredit;
  }

  /// Signs the user out and clears session data.
  Future<void> signOut() async {
  // Sign out from Firebase Auth
  await FirebaseAuth.instance.signOut();

  // Clear local session data
  final box = await Hive.openBox('sessionBox');
  await box.delete('user');
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
    // TODO: implement username change logic
  }

  /// Deletes the user's account and associated data.
  ///
  /// TODO: Implement delete account logic.
  Future<void> deleteAccount() async {
    // TODO: implement delete account logic
  }
}
