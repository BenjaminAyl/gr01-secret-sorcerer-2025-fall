class GamePlayer {
  String username;

  String? vote;

  String role;

  GamePlayer({
    required this.username,
    this.vote,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'vote': vote,
      'role': role,
    };
  }
}