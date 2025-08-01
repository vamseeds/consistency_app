import 'package:consistency_app/screens/login_screen.dart';
import 'package:consistency_app/services/task_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService _taskService = TaskService();
  final List<Task> tasks = [];
  final List<Task> filteredTasks = []; // New: Filtered tasks
  String? selectedFilter = 'All'; // New: Filter state
  bool isLoading = true; // New: Loading state
  bool sortAscending = true; // New: Sort state

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  void handleSessionExpired(var error) async {
    if (error.toString().contains('Session expired')) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _fetchTasks() async {
    setState(() => isLoading = true);
    try {
      final fetchedTasks = await _taskService.fetchTasks();
      setState(() {
        tasks.clear();
        tasks.addAll(fetchedTasks);
        filteredTasks.clear();
        filteredTasks.addAll(tasks); // Initialize filteredTasks
        _sortTasks();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching tasks: $e');
      handleSessionExpired(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load tasks: $e')));
      setState(() => isLoading = false);
    }
  }

  void _filterTasks(String? category) {
    setState(() {
      selectedFilter = category;
      if (category == 'All') {
        filteredTasks.clear();
        filteredTasks.addAll(tasks);
      } else {
        filteredTasks.clear();
        filteredTasks.addAll(
          tasks.where((task) => task.category == category).toList(),
        );
      }
      _sortTasks();
    });
  }

  void _sortTasks() {
    filteredTasks.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return sortAscending
          ? a.dueDate!.compareTo(b.dueDate!)
          : b.dueDate!.compareTo(a.dueDate!);
    });
  }

  void _showAddTaskDialog() async {
    final TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        DateTime? dialogSelectedDate;
        String? errorText;
        String? dropdownValue;
        bool isLoading = false; // New: Loading state
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
                      errorText = value.trim().isEmpty
                          ? 'Title cannot be empty'
                          : value.trim().length > 100
                          ? 'Title must be 100 characters or less'
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
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: controller.text.trim().isNotEmpty && !isLoading
                      ? () async {
                          setDialogState(() => isLoading = true);
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
                              if (selectedFilter == 'All' ||
                                  newTask.category == selectedFilter) {
                                filteredTasks.add(newTask);
                                _sortTasks();
                              }
                              controller.clear();
                            });
                          } catch (e) {
                            print('Error adding task: $e');
                            handleSessionExpired(e);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to add task: $e')),
                            );
                          }
                          setDialogState(() => isLoading = false);
                          Navigator.pop(context);
                        }
                      : null,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Add'),
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
    bool isLoading = false; // New: Loading state

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
                        errorText = value.trim().isEmpty
                            ? 'Title cannot be empty'
                            : value.trim().length > 100
                            ? 'Title must be 100 characters or less'
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
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
                  onPressed: controller.text.trim().isNotEmpty && !isLoading
                      ? () async {
                          setDialogState(() => isLoading = true);

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
                              tasks[tasks.indexWhere((t) => t.id == task.id)] =
                                  updatedTask;
                              if (selectedFilter == 'All' ||
                                  updatedTask.category == selectedFilter) {
                                filteredTasks[index] = updatedTask;
                              } else {
                                filteredTasks.removeAt(index);
                              }
                              _sortTasks();
                            });
                            Navigator.pop(context);
                          } catch (e) {
                            print('Error updating task: $e');
                            handleSessionExpired(e);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update task: $e'),
                              ),
                            );
                          }
                          setDialogState(() => isLoading = false);
                        }
                      : null,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save'),
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
      appBar: AppBar(
        title: const Text('Consistency Planner'),
        actions: [
          IconButton(
            icon: Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
            ),
            onPressed: () {
              setState(() {
                sortAscending = !sortAscending;
                _sortTasks();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('jwt_token');
              print('JWT token removed');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButton<String>(
                    value: selectedFilter,
                    isExpanded: true,
                    hint: const Text('Filter by Category'),
                    items: ['All', 'Work', 'Personal', 'Other']
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      _filterTasks(value);
                    },
                  ),
                ),
                Expanded(
                  child: filteredTasks.isEmpty
                      ? const Center(child: Text('No tasks available'))
                      : ListView.builder(
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            return Dismissible(
                              key: Key(task.id!),
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) async {
                                try {
                                  await _taskService.deleteTask(task.id!);
                                  setState(() {
                                    tasks.removeWhere((t) => t.id == task.id);
                                    filteredTasks.removeAt(index);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${task.title} deleted'),
                                    ),
                                  );
                                } catch (e) {
                                  print('Error deleting task: $e');
                                  handleSessionExpired(e);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to delete task: $e',
                                      ),
                                    ),
                                  );
                                  setState(() {
                                    filteredTasks.insert(index, task);
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
                                          tasks[tasks.indexWhere(
                                                (t) => t.id == task.id,
                                              )] =
                                              updatedTask;
                                          filteredTasks[index] = updatedTask;
                                        });
                                      } catch (e) {
                                        print('Error toggling task: $e');
                                        handleSessionExpired(e);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: task.isCompleted
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (task.dueDate != null)
                                        Text(
                                          task.dueDate!.toString().split(
                                            ' ',
                                          )[0],
                                        ),
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
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () =>
                                        _showEditTaskDialog(task, index),
                                  ),
                                ),
                              ),
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
