class UserStats {
  final int followers;
  final int following;
  final int profileViews;

  UserStats({
    required this.followers,
    required this.following,
    required this.profileViews,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      profileViews: json['profileViews'] ?? json['views'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followers': followers,
      'following': following,
      'profileViews': profileViews,
    };
  }
}
