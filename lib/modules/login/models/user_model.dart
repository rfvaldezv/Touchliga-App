class UserModel {
  const UserModel({
    required this.userId,
    required this.participantId,
    required this.organizationId,
    required this.name,
    required this.email,
    required this.photo,
    required this.active,
    required this.roles,
    required this.leagues,
  });

  final int userId;
  final int participantId;
  final int organizationId;

  final String name;
  final String email;
  final String photo;

  final bool active;

  final List<String> roles;

  final List<int> leagues;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'participantId': participantId,
      'organizationId': organizationId,
      'name': name,
      'email': email,
      'photo': photo,
      'active': active,
      'roles': roles,
      'leagues': leagues,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? 0,
      participantId: json['participantId'] ?? 0,
      organizationId: json['organizationId'] ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      photo: (json['photo'] ?? '').toString(),
      active: json['active'] ?? true,
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      leagues: (json['leagues'] as List?)?.map((e) => e as int).toList() ?? const [],
    );
  }
}
