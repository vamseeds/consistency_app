import 'package:consistency_app/models/task.dart';

class TaskService {
  Future<List<Task>> fetchTasks() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

    return [
      Task(title: "API Task 1", dueDate: DateTime.now()),

      Task(title: "API Task 2", isCompleted: true),

      Task(title: "API Task 3"),
    ];
  }
}
