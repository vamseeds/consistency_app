class Task {
  final String title;
  bool isCompleted;
  final DateTime? dueDate;

  Task({required this.title, this.isCompleted = false, this.dueDate});

  void toggleCompletion() {
    isCompleted = !isCompleted;
  }
}