class Task {
  final String? id; // Add id for MongoDB
  final String title;
  bool isCompleted;
  final DateTime? dueDate;

  Task({this.id, required this.title, this.isCompleted = false, this.dueDate});

  void toggleCompletion() {
    isCompleted = !isCompleted;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completed': isCompleted,
        'dueDate': dueDate?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        isCompleted: json['completed'] ?? false,
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      );
}