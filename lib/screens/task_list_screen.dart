import 'package:consistency_app/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../services/task_service.dart';
import '../models/task.dart';
import '../utils/utils.dart';
import '../utils/extensions.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with SingleTickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  final List<Task> tasks = [];
  final List<Task> filteredTasks = [];
  final TextEditingController _controller = TextEditingController();
  String? selectedFilter = 'All';
  String? selectedDateFilter = 'All';
  bool isLoading = true;
  bool sortAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    setState(() => isLoading = true);
    try {
      final fetchedTasks = await _taskService.fetchTasks(
        context: context,
        onRetry: _fetchTasks,
      );
      if (mounted) {
        setState(() {
          tasks.clear();
          tasks.addAll(fetchedTasks);
          filteredTasks.clear();
          filteredTasks.addAll(tasks);
          _sortTasks();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _filterTasks(String? category) {
    setState(() {
      selectedFilter = category;
      filteredTasks.clear();
      var tempTasks = tasks
          .where(
            (task) =>
                selectedFilter == 'All' || task.category == selectedFilter,
          )
          .toList();
      if (selectedDateFilter == 'Today') {
        final now = DateTime.now();
        filteredTasks.addAll(
          tempTasks.where(
            (task) => task.dueDate != null && task.dueDate!.isSameDate(now),
          ),
        );
      } else if (selectedDateFilter == 'This Week') {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final weekEnd = startOfDay.add(const Duration(days: 7));
        filteredTasks.addAll(
          tempTasks.where(
            (task) =>
                task.dueDate != null &&
                !task.dueDate!.isBefore(startOfDay) &&
                task.dueDate!.isBefore(weekEnd),
          ),
        );
      } else {
        filteredTasks.addAll(tempTasks);
      }
      _sortTasks();
    });
  }

  void _sortTasks() {
    filteredTasks.sort((a, b) {
      const priorityOrder = {'High': 3, 'Medium': 2, 'Low': 1};
      final aPriority = priorityOrder[a.priority ?? 'Low'] ?? 1;
      final bPriority = priorityOrder[b.priority ?? 'Low'] ?? 1;
      if (aPriority != bPriority) {
        return sortAscending
            ? bPriority.compareTo(aPriority)
            : aPriority.compareTo(bPriority);
      }
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return sortAscending
          ? a.dueDate!.compareTo(b.dueDate!)
          : b.dueDate!.compareTo(a.dueDate!);
    });
  }

  Future<void> _deleteTask(Task task, int index) async {
    final deletedTask = task;
    setState(() {
      filteredTasks.removeAt(index);
    });
    try {
      await _taskService.deleteTask(
        task.id!,
        context: context,
        onRetry: () => _deleteTask(task, index),
      );
      if (mounted) {
        setState(() {
          tasks.removeWhere((t) => t.id == task.id);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${task.title} deleted')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          filteredTasks.insert(index, deletedTask);
        });
      }
    }
  }

  Future<void> _toggleTask(String id, bool value, int index) async {
    try {
      final updatedTask = await _taskService.toggleTask(
        id,
        value,
        context: context,
        onRetry: () => _toggleTask(id, value, index),
      );
      if (mounted) {
        setState(() {
          tasks[tasks.indexWhere((t) => t.id == id)] = updatedTask;
          filteredTasks[index] = updatedTask;
        });
      }
    } catch (e) {
      print('Toggle task failed: $e');
    }
  }

  void _showAddTaskDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        final TextEditingController controller = TextEditingController();
        String? dropdownValue;
        String? priorityValue;
        DateTime? selectedDate;
        String? errorText;
        bool isLoading = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: SizedBox(
                height: 400,
                width: 300,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Task Title',
                          hintText: 'Enter task title',
                          errorText: errorText,
                          border: const OutlineInputBorder(),
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
                        value: dropdownValue,
                        hint: const Text('Select Category'),
                        isExpanded: true,
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
                      DropdownButton<String>(
                        value: priorityValue,
                        hint: const Text('Select Priority'),
                        isExpanded: true,
                        items: ['Low', 'Medium', 'High']
                            .map(
                              (priority) => DropdownMenuItem(
                                value: priority,
                                child: Text(priority),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            priorityValue = value;
                          });
                        },
                      ),
                      TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime(2026),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Text(
                          selectedDate == null
                              ? 'Select Due Date'
                              : selectedDate.toString().split(' ')[0],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
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
                                dueDate: selectedDate,
                                category: dropdownValue,
                                priority: priorityValue,
                              ),
                              context: dialogContext,
                              onRetry: () => _showAddTaskDialog(),
                            );
                            if (context.mounted) {
                              setState(() {
                                tasks.add(newTask);
                                if (selectedFilter == 'All' ||
                                    newTask.category == selectedFilter) {
                                  filteredTasks.add(newTask);
                                  _sortTasks();
                                }
                              });
                              Navigator.pop(dialogContext);
                            }
                          } catch (e) {
                            print('Create task failed: $e');
                          }
                          setDialogState(() => isLoading = false);
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
    await showDialog(
      context: context,
      builder: (dialogContext) {
        final TextEditingController controller = TextEditingController(
          text: task.title,
        );
        String? dropdownValue = task.category;
        String? priorityValue = task.priority;
        DateTime? selectedDate = task.dueDate != null
            ? DateTime(
                task.dueDate!.year,
                task.dueDate!.month,
                task.dueDate!.day,
              )
            : null;
        String? errorText;
        bool isLoading = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Task'),
              content: SizedBox(
                height: 400,
                width: 300,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Task Title',
                          hintText: 'Enter task title',
                          errorText: errorText,
                          border: const OutlineInputBorder(),
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
                        value: dropdownValue,
                        hint: const Text('Select Category'),
                        isExpanded: true,
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
                      DropdownButton<String>(
                        value: priorityValue,
                        hint: const Text('Select Priority'),
                        isExpanded: true,
                        items: ['Low', 'Medium', 'High']
                            .map(
                              (priority) => DropdownMenuItem(
                                value: priority,
                                child: Text(priority),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            priorityValue = value;
                          });
                        },
                      ),
                      TextButton(
                        onPressed: () async {
                          final DateTime initialDate =
                              selectedDate ?? DateTime.now();
                          final DateTime? picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: DateTime(
                              initialDate.year,
                              initialDate.month,
                              initialDate.day,
                            ),
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime(2026),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Text(
                          selectedDate == null
                              ? 'Select Due Date'
                              : selectedDate.toString().split(' ')[0],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
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
                                completed: task.completed,
                                dueDate: selectedDate,
                                category: dropdownValue,
                                priority: priorityValue,
                              ),
                              context: dialogContext,
                              onRetry: () => _showEditTaskDialog(task, index),
                            );
                            if (context.mounted) {
                              setState(() {
                                tasks[tasks.indexWhere(
                                      (t) => t.id == task.id,
                                    )] =
                                    updatedTask;
                                if (selectedFilter == 'All' ||
                                    updatedTask.category == selectedFilter) {
                                  filteredTasks[index] = updatedTask;
                                } else {
                                  filteredTasks.removeAt(index);
                                }
                                _sortTasks();
                              });
                              Navigator.pop(dialogContext);
                            }
                          } catch (e) {
                            print('Update task failed: $e');
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
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('jwt_token');
                print('JWT token cleared');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out successfully')),
                  );
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                handleErrorWithRetry(
                  context,
                  e,
                  () async {
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('jwt_token');
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      print('Retry logout failed: $e');
                    }
                  },
                  errorMessage: 'Failed to log out',
                  isMounted: mounted,
                );
              }
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
                  child: Row(
                    children: [
                      Expanded(
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
                            setState(() {
                              selectedFilter = value;
                              _filterTasks(value);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedDateFilter,
                          isExpanded: true,
                          hint: const Text('Filter by Due Date'),
                          items: ['All', 'Today', 'This Week']
                              .map(
                                (filter) => DropdownMenuItem(
                                  value: filter,
                                  child: Text(filter),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedDateFilter = value;
                              _filterTasks(selectedFilter);
                            });
                          },
                        ),
                      ),
                    ],
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
                              onDismissed: (direction) =>
                                  _deleteTask(task, index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                child: Card(
                                  child: AnimatedOpacity(
                                    opacity: task.completed ? 0.5 : 1.0,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                    child: ListTile(
                                      leading: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Checkbox(
                                            value: task.completed,
                                            onChanged: (value) => _toggleTask(
                                              task.id!,
                                              value!,
                                              index,
                                            ),
                                          ),
                                        ],
                                      ),
                                      title: Text(
                                        task.title,
                                        style: TextStyle(
                                          color: task.priority == 'High'
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.error
                                              : task.priority == 'Medium'
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.secondary
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        task.dueDate != null
                                            ? task.dueDate.toString().split(
                                                ' ',
                                              )[0]
                                            : 'No due date',
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () =>
                                            _showEditTaskDialog(task, index),
                                      ),
                                    ),
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
