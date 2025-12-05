class AppUser {
  final String uid;
  final String email;
  final String username;
  final String nickname;
  final String hatColor;
  final String avatarColor;
  final int wins;
  final int losses;
  final int exp;
  final int currentLevel;

  const AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.nickname,
    this.wins = 0,
    this.losses = 0,
    this.hatColor = 'hatDefault',
    this.avatarColor = 'avatarDefault',
    required this.exp,
    required this.currentLevel,
  });

  factory AppUser.fromMap(Map data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      nickname: data['nickname'] ?? '',
      hatColor: data['hatColor'] ?? 'hatDefault',
      avatarColor: data['avatarColor'] ?? 'avatarDefault',
      wins: data['wins'] ?? 0,
      losses: data['losses'] ?? 0,
      exp: data['exp'] ?? 0,
      currentLevel: data['currentLevel'] ?? 0
    );
  

  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'username': username,
        'nickname': nickname,
        'nickame': nickname,
        'hatColor': hatColor,
        'avatarColor': avatarColor,
        'wins': wins,
        'losses': losses,
        'exp': exp,
        'currentLevel': currentLevel
      };
}
