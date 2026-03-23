class TraineeModel {
  final String id;
  final String name;
  final String email;

  const TraineeModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory TraineeModel.fromJson(Map<String, dynamic> json) {
    return TraineeModel(
      id: json['id'] as String,
      name: (json['name'] ?? '') as String,
      email: json['email'] ?? '',
    );
  }
}
