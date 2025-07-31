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
        final TextEditingController controller = TextEditingController();
        DateTime? dialogSelectedDate;
        String? errorText;
        String? dropdownValue;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
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
                  DropdownButton<String>(
                    value: dropdownValue,
                    hint: const Text('Select Category'),
                    items: ['Work', 'Personal', 'Other']
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,

                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        dropdownValue = value;
                      });
                    },
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
                  onPressed: () {
                    controller.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: controller.text.trim().isNotEmpty
                      ? () async {
                          try {
                            Task newTask = await _taskService.createTask(
                              Task(
                                title: controller.text.trim(),
                                dueDate: dialogSelectedDate,
                                category: dropdownValue,
                              ),
                            );
                            setState(() {
                              tasks.add(newTask);
                              controller.clear();
                              controller.dispose();
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

  void _showEditTaskDialog(Task task, int index) async {
    final TextEditingController controller = TextEditingController(
      text: task.title,
    );
    String? selectedCategory = task.category;
    DateTime? selectedDate = task.dueDate;
    String? errorText;
    await showDialog(
      context: context,
      builder: (context) {
        String? dialogCategory = selectedCategory;
        DateTime? dialogSelectedDate = selectedDate;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'Enter task title',
                      errorText: errorText,
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        errorText = value.isEmpty
                            ? 'Title cannot be empty'
                            : null;
                      });
                    },
                  ),
                  DropdownButton<String>(
                    value: dialogCategory,
                    hint: const Text('Select Category'),
                    isExpanded: true,
                    items: ['Work', 'Personal', 'Other'].map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        dialogCategory = newValue;
                      });
                    },
                  ),
                  TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: dialogSelectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2026),
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
                  onPressed: controller.text.trim().isNotEmpty
                      ? () async {
                          try {
                            Task updatedTask = await _taskService.updateTask(
                              Task(
                                id: task.id,
                                title: controller.text.trim(),
                                isCompleted: task.isCompleted,
                                dueDate: dialogSelectedDate,
                                category: dialogCategory,
                              ),
                            );
                            setState(() {
                              tasks[index] = updatedTask;
                            });
                            Navigator.pop(context);
                          } catch (e) {
                            print('Error updating task: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update task: $e'),
                              ),
                            );
                          }
                        }
                      : null,
                  child: const Text('Save'),
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
                        child: Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
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
                                      content: Text(
                                        'Failed to toggle task: $e',
                                      ),
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
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (task.dueDate != null)
                                  Text(task.dueDate!.toString().split(' ')[0]),
                                if (task.category != null)
                                  Text(
                                    task.category!,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditTaskDialog(task, index),
                            ),
                          ),
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
