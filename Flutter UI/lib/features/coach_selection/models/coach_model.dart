/// Matches API response: { id, name, email }
/// NOTE: the backend returns name = email (c.UserName aliased),
/// so we display email as the primary identifier.
class CoachModel {
  final String id;
  final String name;
  final String email;

  const CoachModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory CoachModel.fromJson(Map<String, dynamic> json) => CoachModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '', // same as email from backend
        email: json['email']?.toString() ?? '',
      );

  /// Display label — use email since name == email from this API
  String get displayName => name.isNotEmpty ? name : email;
}
