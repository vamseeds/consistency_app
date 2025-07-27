import 'package:flutter/material.dart';
import 'models/task.dart';

void main() {
  runApp(const ConsistencyApp());
}

class ConsistencyApp extends StatelessWidget {
  const ConsistencyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consistency App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TaskListScreen(),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final List<Task> tasks = [
    Task(title: "Morning workout", dueDate: DateTime.now()),
    Task(title: "Read book", isCompleted: true),
    Task(title: "Plan tomorrow"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
            leading: Checkbox(
              value: task.isCompleted,
              onChanged: (value) {
                setState(() {
                  task.toggleCompletion();
                });
              },
            ),
            title: Text(task.title),
            subtitle: task.dueDate != null
                ? Text(task.dueDate.toString().split(' ')[0])
                : null,
          );
        },
      ),
    );
  }
}