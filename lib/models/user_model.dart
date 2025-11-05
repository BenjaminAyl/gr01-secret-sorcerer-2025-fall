class AppUser {
  final String uid;
  final String email;
  final String username;
  final String nickname;

  const AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.nickname,
  });

  factory AppUser.fromMap(Map data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      nickname: data['nickname'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'username': username,
        'nickame': nickname,
      };
}
