class AppUser {
  final String uid;
  final String email;
  final String username;
  final String nickname;
  final String hatColor;
  final int wins;
  final int losses;

  const AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.nickname,
    this.wins = 0,
    this.losses = 0,
    this.hatColor = 'hatDefault',
  });

  factory AppUser.fromMap(Map data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      nickname: data['nickname'] ?? '',
      hatColor: data['hatColor'] ?? 'hatDefault',
      wins: data['wins'] ?? 0,
      losses: data['losses'] ?? 0,
    );
  

  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'username': username,
        'nickname': nickname,
        'nickame': nickname,
        'wins': wins,
        'losses': losses,
      };
}
