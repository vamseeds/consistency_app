class Task {
  String? id; 
  String title;
  bool completed;
  DateTime? dueDate;
  String? category;
  String? priority; // New field: Low, Medium, High

  Task({
    this.id,
    required this.title,
    this.completed = false,
    this.dueDate,
    this.category,
    this.priority,
  });
  void toggleCompletion() {
    completed = !completed;
  }

 factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String?,
      title: json['title'] as String,
      completed: json['completed'] as bool? ?? false,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      category: json['category'] as String?,
      priority: json['priority'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'dueDate': dueDate?.toIso8601String(),
      'category': category,
      'priority': priority,
    };
  }
  }
