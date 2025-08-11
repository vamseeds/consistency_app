import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../services/task_service.dart';
import '../models/task.dart';
import '../utils/utils.dart';
import '../main.dart';

extension DateOnlyCompare on DateTime {
    bool isSameDate(DateTime other) {
        return year == other.year &&
            month == other.month &&
            day == other.day;
    }
}

class TaskListScreen extends StatefulWidget {
    @override
    _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
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
            final fetchedTasks = await _taskService.fetchTasks();
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
            handleErrorWithRetry(
              context,
              e,
              _fetchTasks,
              errorMessage: 'Failed to load tasks',
              isMounted: mounted,
            );
            if (mounted) {
                setState(() => isLoading = false);
            }
        }
    }

    void _filterTasks(String? category) {
        setState(() {
            selectedFilter = category;
            filteredTasks.clear();
            var tempTasks = tasks.where((task) => selectedFilter == 'All' || task.category == selectedFilter).toList();
            if (selectedDateFilter == 'Today') {
                final now = DateTime.now();
                filteredTasks.addAll(tempTasks.where((task) => task.dueDate != null && task.dueDate!.isSameDate(now)));
            } else if (selectedDateFilter == 'This Week') {
                final now = DateTime.now();
                final startOfDay = DateTime(now.year, now.month, now.day);
                final weekEnd = startOfDay.add(const Duration(days: 7));
                filteredTasks.addAll(tempTasks.where((task) => task.dueDate != null && !task.dueDate!.isBefore(startOfDay) && task.dueDate!.isBefore(weekEnd)));
            } else {
                filteredTasks.addAll(tempTasks);
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
        await showDialog(
            context: context,
            builder: (dialogContext) {
                final TextEditingController controller = TextEditingController();
                String? dropdownValue;
                DateTime? selectedDate;
                String? errorText;
                bool isLoading = false;
                return StatefulBuilder(
                    builder: (dialogContext, setDialogState) {
                        return AlertDialog(
                            title: const Text('Add Task'),
                            content: SizedBox(
                                height: 300,
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
                                                    .map((category) => DropdownMenuItem(
                                                          value: category,
                                                          child: Text(category),
                                                      ))
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
                                                        context: dialogContext,
                                                        initialDate: DateTime.now(),
                                                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
                                                      ),
                                                  );
                                                  if (context.mounted) {
                                                      setState(() {
                                                          tasks.add(newTask);
                                                          if (selectedFilter == 'All' || newTask.category == selectedFilter) {
                                                              filteredTasks.add(newTask);
                                                              _sortTasks();
                                                          }
                                                      });
                                                      Navigator.pop(dialogContext);
                                                  }
                                              } catch (e) {
                                                  handleErrorWithRetry(
                                                    dialogContext,
                                                    e,
                                                    () => _showAddTaskDialog(),
                                                    errorMessage: 'Failed to add task',
                                                    isMounted: context.mounted,
                                                  );
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
                final TextEditingController controller = TextEditingController(text: task.title);
                String? dropdownValue = task.category;
                DateTime? selectedDate = task.dueDate != null
                    ? DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day)
                    : null;
                String? errorText;
                bool isLoading = false;
                return StatefulBuilder(
                    builder: (dialogContext, setDialogState) {
                        return AlertDialog(
                            title: const Text('Edit Task'),
                            content: SizedBox(
                                height: 300,
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
                                                    .map((category) => DropdownMenuItem(
                                                          value: category,
                                                          child: Text(category),
                                                      ))
                                                    .toList(),
                                                onChanged: (value) {
                                                    setDialogState(() {
                                                        dropdownValue = value;
                                                    });
                                                },
                                            ),
                                            TextButton(
                                                onPressed: () async {
                                                    final DateTime initialDate = selectedDate ?? DateTime.now();
                                                    final DateTime? picked = await showDatePicker(
                                                        context: dialogContext,
                                                        initialDate: DateTime(
                                                            initialDate.year,
                                                            initialDate.month,
                                                            initialDate.day,
                                                        ),
                                                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
                                                          isCompleted: task.isCompleted,
                                                          dueDate: selectedDate,
                                                          category: dropdownValue,
                                                      ),
                                                  );
                                                  if (context.mounted) {
                                                      setState(() {
                                                          tasks[tasks.indexWhere((t) => t.id == task.id)] = updatedTask;
                                                          if (selectedFilter == 'All' || updatedTask.category == selectedFilter) {
                                                              filteredTasks[index] = updatedTask;
                                                          } else {
                                                              filteredTasks.removeAt(index);
                                                          }
                                                          _sortTasks();
                                                      });
                                                      Navigator.pop(dialogContext);
                                                  }
                                              } catch (e) {
                                                  handleErrorWithRetry(
                                                    dialogContext,
                                                    e,
                                                    () => _showEditTaskDialog(task, index),
                                                    errorMessage: 'Failed to update task',
                                                    isMounted: context.mounted,
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
                        icon: Icon(sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
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
                                              MaterialPageRoute(builder: (context) => LoginScreen()),
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
                                                .map((category) => DropdownMenuItem(
                                                      value: category,
                                                      child: Text(category),
                                                  ))
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
                                                .map((filter) => DropdownMenuItem(
                                                      value: filter,
                                                      child: Text(filter),
                                                  ))
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
                                                child: const Icon(Icons.delete, color: Colors.white),
                                            ),
                                            direction: DismissDirection.endToStart,
                                            onDismissed: (direction) async {
                                                try {
                                                    await _taskService.deleteTask(task.id!);
                                                    if (mounted) {
                                                        setState(() {
                                                            tasks.removeWhere((t) => t.id == task.id);
                                                            filteredTasks.removeAt(index);
                                                        });
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('${task.title} deleted')),
                                                        );
                                                    }
                                                } catch (e) {
                                                    handleErrorWithRetry(
                                                      context,
                                                      e,
                                                      () async {
                                                        try {
                                                            await _taskService.deleteTask(task.id!);
                                                            if (context.mounted) {
                                                                setState(() {
                                                                    tasks.removeWhere((t) => t.id == task.id);
                                                                    filteredTasks.removeAt(index);
                                                                });
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                    SnackBar(content: Text('${task.title} deleted')),
                                                                );
                                                            }
                                                        } catch (e) {
                                                            print('Retry delete failed: $e');
                                                        }
                                                      },
                                                      errorMessage: 'Failed to delete task',
                                                      isMounted: mounted,
                                                    );
                                                    if (mounted) {
                                                        setState(() {
                                                            filteredTasks.insert(index, task);
                                                        });
                                                    }
                                                }
                                            },
                                            child: Card(
                                                child: AnimatedOpacity(
                                                    opacity: task.isCompleted ? 0.5 : 1.0,
                                                    duration: const Duration(milliseconds: 400),
                                                    curve: Curves.easeInOut,
                                                    child: ListTile(
                                                        leading: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                                Checkbox(
                                                                    value: task.isCompleted,
                                                                    onChanged: (value) async {
                                                                        try {
                                                                            final updatedTask = await _taskService.toggleTask(task.id!, value!);
                                                                            if (mounted) {
                                                                                setState(() {
                                                                                    tasks[tasks.indexWhere((t) => t.id == task.id)] = updatedTask;
                                                                                    filteredTasks[index] = updatedTask;
                                                                                });
                                                                            }
                                                                        } catch (e) {
                                                                            handleErrorWithRetry(
                                                                              context,
                                                                              e,
                                                                              () async {
                                                                                try {
                                                                                    final updatedTask = await _taskService.toggleTask(task.id!, value!);
                                                                                    if (context.mounted) {
                                                                                        setState(() {
                                                                                            tasks[tasks.indexWhere((t) => t.id == task.id)] = updatedTask;
                                                                                            filteredTasks[index] = updatedTask;
                                                                                        });
                                                                                    }
                                                                                } catch (e) {
                                                                                    print('Retry toggle failed: $e');
                                                                                }
                                                                              },
                                                                              errorMessage: 'Failed to toggle task',
                                                                              isMounted: mounted,
                                                                            );
                                                                        }
                                                                    },
                                                                ),
                                                                AnimatedSwitcher(
                                                                    duration: const Duration(milliseconds: 400),
                                                                    child: task.isCompleted
                                                                        ? const Icon(
                                                                            Icons.check_circle,
                                                                            color: Colors.green,
                                                                            key: ValueKey('completed'),
                                                                          )
                                                                        : const SizedBox.shrink(
                                                                            key: ValueKey('incomplete'),
                                                                          ),
                                                                ),
                                                            ],
                                                        ),
                                                        title: Text(
                                                            task.title,
                                                            style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.w500,
                                                                color: task.isCompleted ? Colors.grey : Colors.black,
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
                                                                        style: const TextStyle(color: Colors.blue, fontStyle: FontStyle.italic),
                                                                    ),
                                                            ],
                                                        ),
                                                        trailing: IconButton(
                                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                                            onPressed: () => _showEditTaskDialog(task, index),
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
