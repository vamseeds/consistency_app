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

  final TextEditingController _controller = TextEditingController();

  void _showAddTaskDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        DateTime? dialogSelectedDate;
        String? errorText;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'Enter task title',
                      errorText: errorText,
                    ),
                    onChanged: (value) => setDialogState(() {
                      errorText = value.isEmpty
                          ? 'Title Cannot be empty'
                          : null;
                    }),
                  ),
                  TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          dialogSelectedDate = picked;
                        });
                      }
                    },
                    child: Text(
                      dialogSelectedDate == null
                          ? 'Select Due Date'
                          : dialogSelectedDate.toString().split(' ')[0],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      setState(() {
                        tasks.add(
                          Task(
                            title: _controller.text,
                            dueDate: dialogSelectedDate,
                          ),
                        );
                        _controller.clear();
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Your Tasks',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
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
                  title: Text(
                    task.title,
                    style: TextStyle(
                      color: task.isCompleted
                          ? Colors.grey
                          : (task.dueDate != null &&
                                    task.dueDate!.isBefore(DateTime.now())
                                ? Colors.red
                                : Colors.black),
                    ),
                  ),
                  subtitle: task.dueDate != null
                      ? Text(task.dueDate.toString().split(' ')[0])
                      : null,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,

        child: const Icon(Icons.add),
      ),
    );
  }
}
