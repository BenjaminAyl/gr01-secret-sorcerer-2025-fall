import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/models/user_model.dart';

class FriendsController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseController _fb = FirebaseController();

  String _friendRequestId(String fromUid, String toUid) =>
      '${fromUid}_${toUid}';

  Future<void> sendFriendRequestToUsername(String toUsername) async {
    final from = _fb.currentUser;
    if (from == null) throw Exception('Not signed in');

    final username = toUsername.trim().toLowerCase();
    if (username.isEmpty) throw Exception('Username empty');

    // find recipient by username
    QuerySnapshot<Map<String, dynamic>> q;
    try {
      q = await _firestore
          .collection('users')
          .where('Username', isEqualTo: username)
          .limit(1)
          .get();
    } catch (e, st) {
      rethrow;
    }
    if (q.docs.isEmpty) throw Exception('User not found');

    final toDoc = q.docs.first;
    final toUid = toDoc.id;
    if (toUid == from.uid) throw Exception('Cannot friend yourself');

    // check if already friends
    final alreadyFriend = await _firestore
        .collection('users')
        .doc(from.uid)
        .collection('friends')
        .doc(toUid)
        .get();
    if (alreadyFriend.exists) throw Exception('Already friends');

    // check for reverse pending request (they already sent to you)
    final reverseId = _friendRequestId(toUid, from.uid);
    DocumentSnapshot<Map<String, dynamic>> reverseDoc;
    try {
      reverseDoc = await _firestore
          .collection('friend_requests')
          .doc(reverseId)
          .get();
    } catch (e, st) {
      rethrow;
    }
    if (reverseDoc.exists &&
        (reverseDoc.data()?['status'] ?? 'pending') == 'pending') {
      // accept the reverse request instead of creating a new one
      await acceptFriendRequest(fromUid: toUid);
      return;
    }

    // check if outgoing request already exists
    final reqId = _friendRequestId(from.uid, toUid);
    final reqRef = _firestore.collection('friend_requests').doc(reqId);
    DocumentSnapshot<Map<String, dynamic>> reqSnap;
    try {
      reqSnap = await reqRef.get();
    } catch (e, st) {
      rethrow;
    }
    if (reqSnap.exists &&
        (reqSnap.data()?['status'] ?? 'pending') == 'pending') {
      throw Exception('Request already sent');
    }

    DocumentSnapshot<Map<String, dynamic>> fromDoc;
    try {
      fromDoc = await _firestore.collection('users').doc(from.uid).get();
    } catch (e, st) {
      rethrow;
    }
    final fromData = fromDoc.data() ?? {};

    final payload = {
      'fromUid': from.uid,
      'toUid': toUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'fromUsername': (fromData['Username'] ?? fromData['username'] ?? '')
          .toString(),
      'fromNickname': (fromData['Nickname'] ?? fromData['nickname'] ?? '')
          .toString(),
    };

    try {
      await reqRef.set(payload);
    } catch (e, st) {
      rethrow;
    }
    // Also create a per-recipient incoming_requests doc to avoid composite-index queries
    // Path: users/{toUid}/incoming_requests/{fromUid}
    try {
      await _firestore
          .collection('users')
          .doc(toUid)
          .collection('incoming_requests')
          .doc(from.uid)
          .set({
            'fromUid': from.uid,
            'fromUsername': payload['fromUsername'],
            'fromNickname': payload['fromNickname'],
            'status': payload['status'],
            'createdAt': payload['createdAt'],
          });
    } catch (e, st) {}
  }

  Future<void> acceptFriendRequest({required String fromUid}) async {
    final to = _fb.currentUser;
    if (to == null) throw Exception('Not signed in');

    final reqId = _friendRequestId(fromUid, to.uid);
    final reqRef = _firestore.collection('friend_requests').doc(reqId);

    try {
      await _firestore.runTransaction((tx) async {
        final reqSnap = await tx.get(reqRef);
        if (!reqSnap.exists) return;
        final data = reqSnap.data()!;
        if ((data['status'] ?? '') != 'pending') return;

        // create friend entries for both users
        final fromUserDoc = await tx.get(
          _firestore.collection('users').doc(fromUid),
        );
        final toUserDoc = await tx.get(
          _firestore.collection('users').doc(to.uid),
        );

        final fromData = fromUserDoc.data() ?? {};
        final toData = toUserDoc.data() ?? {};

        final fromFriendRef = _firestore
            .collection('users')
            .doc(fromUid)
            .collection('friends')
            .doc(to.uid);
        final toFriendRef = _firestore
            .collection('users')
            .doc(to.uid)
            .collection('friends')
            .doc(fromUid);

        tx.set(fromFriendRef, {
          'uid': to.uid,
          'username': (toData['Username'] ?? toData['username'] ?? '')
              .toString(),
          'nickname': (toData['Nickname'] ?? toData['nickname'] ?? '')
              .toString(),
          'email': (toData['Email'] ?? toData['email'] ?? '').toString(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        tx.set(toFriendRef, {
          'uid': fromUid,
          'username': (fromData['Username'] ?? fromData['username'] ?? '')
              .toString(),
          'nickname': (fromData['Nickname'] ?? fromData['nickname'] ?? '')
              .toString(),
          'email': (fromData['Email'] ?? fromData['email'] ?? '').toString(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // delete the request
        tx.delete(reqRef);
        // also delete the per-user incoming request doc if present
        final incomingRef = _firestore
            .collection('users')
            .doc(to.uid)
            .collection('incoming_requests')
            .doc(fromUid);
        tx.delete(incomingRef);
      });
    } catch (e, st) {
      rethrow;
    }
  }

  Future<void> declineFriendRequest({required String fromUid}) async {
    final to = _fb.currentUser;
    if (to == null) throw Exception('Not signed in');

    final reqId = _friendRequestId(fromUid, to.uid);
    final reqRef = _firestore.collection('friend_requests').doc(reqId);
    await reqRef.delete();
    // also delete per-user incoming doc
    try {
      await _firestore
          .collection('users')
          .doc(to.uid)
          .collection('incoming_requests')
          .doc(fromUid)
          .delete();
    } catch (_) {}
  }

  Future<void> removeFriend(String friendUid) async {
    final me = _fb.currentUser;
    if (me == null) throw Exception('Not signed in');

    final a = _firestore
        .collection('users')
        .doc(me.uid)
        .collection('friends')
        .doc(friendUid);
    final b = _firestore
        .collection('users')
        .doc(friendUid)
        .collection('friends')
        .doc(me.uid);

    await _firestore.runTransaction((tx) async {
      tx.delete(a);
      tx.delete(b);
    });
  }

  Stream<List<AppUser>> watchFriends() {
    final me = _fb.currentUser;
    if (me == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(me.uid)
        .collection('friends')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => AppUser.fromMap({
                  'uid': d.data()['uid'] ?? d.id,
                  'email': d.data()['email'] ?? '',
                  'username': d.data()['username'] ?? '',
                  'nickname': d.data()['nickname'] ?? '',
                }),
              )
              .toList(),
        );
  }

  Stream<List<AppUser>> watchIncomingRequests() {
    final me = _fb.currentUser;
    if (me == null) return const Stream.empty();
    // Read from per-user subcollection to avoid composite-index requirements
    return _firestore
        .collection('users')
        .doc(me.uid)
        .collection('incoming_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final data = d.data();
            return AppUser.fromMap({
              'uid': data['fromUid'] ?? d.id,
              'email': data['fromEmail'] ?? '',
              'username': data['fromUsername'] ?? '',
              'nickname': data['fromNickname'] ?? '',
            });
          }).toList(),
        );
  }
}
