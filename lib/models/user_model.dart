// models/user_model.dart
class UserModel {
  final String id;
  final String username;
  String password;
  final String role;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? '',
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
      'createdAt': createdAt,
    };
  }
}
