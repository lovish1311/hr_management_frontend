class CompanyGame {
  final String gameKey;
  final String title;
  final String description;
  final String category;
  final String iconName;
  final String gradientStart;
  final String gradientEnd;
  final bool isEnabled;
  final String allowedRoles;
  final int minPlayers;
  final int maxPlayers;

  CompanyGame({
    required this.gameKey,
    required this.title,
    required this.description,
    required this.category,
    required this.iconName,
    required this.gradientStart,
    required this.gradientEnd,
    required this.isEnabled,
    required this.allowedRoles,
    required this.minPlayers,
    required this.maxPlayers,
  });

  factory CompanyGame.fromJson(Map<String, dynamic> json) {
    return CompanyGame(
      gameKey: json['gameKey'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Casual',
      iconName: json['iconName'] ?? 'sports_esports',
      gradientStart: json['gradientStart'] ?? '#312E81',
      gradientEnd: json['gradientEnd'] ?? '#4338CA',
      isEnabled: json['isEnabled'] ?? true,
      allowedRoles: json['allowedRoles'] ?? 'ROLE_EMPLOYEE,ROLE_HR_ADMIN,ROLE_SUPER_ADMIN',
      minPlayers: json['minPlayers'] ?? 2,
      maxPlayers: json['maxPlayers'] ?? 100,
    );
  }

  CompanyGame copyWith({
    bool? isEnabled,
    String? allowedRoles,
  }) {
    return CompanyGame(
      gameKey: gameKey,
      title: title,
      description: description,
      category: category,
      iconName: iconName,
      gradientStart: gradientStart,
      gradientEnd: gradientEnd,
      isEnabled: isEnabled ?? this.isEnabled,
      allowedRoles: allowedRoles ?? this.allowedRoles,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
    );
  }
}
