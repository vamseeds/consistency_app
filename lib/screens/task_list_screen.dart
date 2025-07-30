import 'package:consistency_app/services/task_service.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService _taskService = TaskService();
  final List<Task> tasks = [];
  final TextEditingController _controller = TextEditingController();
  late Future<List<Task>> _taskFuture;

  @override
  void initState() {
    super.initState();
    _taskFuture = _taskService.fetchTasks();
  }

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
                  onPressed: _controller.text.trim().isNotEmpty
                      ? () async {
                          try {
                            Task newTask = await _taskService.createTask(
                              Task(
                                title: _controller.text.trim(),
                                dueDate: dialogSelectedDate,
                              ),
                            );
                            setState(() {
                              tasks.add(newTask);
                              _controller.clear();
                            });
                            Navigator.pop(context);
                          } catch (e) {
                            print('Error adding task: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to add task: $e')),
                            );
                          }
                        }
                      : null,
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
      body: FutureBuilder<List<Task>>(
        future: _taskFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tasks found'));
          } else {
            if (tasks.isEmpty) {
              tasks.addAll(snapshot.data!);
            }
            return Column(
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
                      return Dismissible(
                        key: Key(task.id!), // Unique key for each task
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) async {
                          try {
                            await _taskService.deleteTask(task.id!);
                            setState(() {
                              tasks.removeAt(index);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${task.title} deleted')),
                            );
                          } catch (e) {
                            print('Error deleting task: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete task: $e'),
                              ),
                            );
                            setState(() {
                              tasks.insert(index, task); // Revert on error
                            });
                          }
                        },
                        child: ListTile(
                          leading: Checkbox(
                            value: task.isCompleted,
                            onChanged: (value) async {
                              try {
                                final updatedTask = await _taskService
                                    .toggleTask(task.id!, value!);
                                setState(() {
                                  tasks[index] =
                                      updatedTask; // Update local list
                                });
                              } catch (e) {
                                print('Error toggling task: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to toggle task: $e'),
                                  ),
                                );
                              }
                            },
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              color: task.isCompleted
                                  ? Colors.grey
                                  : (task.dueDate != null &&
                                            task.dueDate!.isBefore(
                                              DateTime.now(),
                                            )
                                        ? Colors.red
                                        : Colors.black),
                            ),
                          ),
                          subtitle: task.dueDate != null
                              ? Text(task.dueDate.toString().split(' ')[0])
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,

        child: const Icon(Icons.add),
      ),
    );
  }
}
