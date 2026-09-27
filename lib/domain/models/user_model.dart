class UserModel {
  final int id;
  final String username;
  final String email;
  final String? name;
  final String createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.name,
    required this.createdAt,
  });

  String get displayName => (name != null && name!.trim().isNotEmpty) ? name!.trim() : username;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'created_at': createdAt,
    };
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? name,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
