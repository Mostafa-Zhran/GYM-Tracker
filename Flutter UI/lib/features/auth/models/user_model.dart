class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String token;
  final String? coachId;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
    this.coachId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // ✅ "roles" is an array — take first element
    final rolesRaw = json['roles'];
    final role = rolesRaw is List
        ? (rolesRaw.isNotEmpty ? rolesRaw[0] as String : '')
        : (json['role'] as String? ?? '');

    return UserModel(
      id: json['id'] as String,
      name: json['userName'] as String, // ✅ "userName" not "name"
      email: json['email'] as String,
      role: role, // ✅ from "roles" array
      token: json['token'] as String,
      coachId: json['coachId'] as String?, // ✅ already in response
    );
  }
}
