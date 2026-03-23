// TODO Implement this library.
class TodayWorkoutModel {
  final String title;
  final String description;
  final DateTime scheduledDate;
  final String coachName;
  final String traineeName;
  final WorkoutLogModel? log;

  TodayWorkoutModel({
    required this.title,
    required this.description,
    required this.scheduledDate,
    required this.coachName,
    required this.traineeName,
    this.log,
  });

  bool get isLogged => log != null;

  factory TodayWorkoutModel.fromJson(Map<String, dynamic> json) {
    return TodayWorkoutModel(
      title: json['title'],
      description: json['description'] ?? '',
      scheduledDate: DateTime.parse(json['scheduledDate']),
      coachName: json['coachName'],
      traineeName: json['traineeName'],
      log: json['log'] != null ? WorkoutLogModel.fromJson(json['log']) : null,
    );
  }
}

class WorkoutLogModel {
  final DateTime completedAt;
  final String notes;

  WorkoutLogModel({
    required this.completedAt,
    required this.notes,
  });

  factory WorkoutLogModel.fromJson(Map<String, dynamic> json) {
    return WorkoutLogModel(
      completedAt: DateTime.parse(json['completedAt']),
      notes: json['notes'] ?? '',
    );
  }
}
