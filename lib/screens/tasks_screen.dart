import "package:flutter/material.dart";
import "package:intl/intl.dart";

enum TaskFilters { today, all, done }

class Task {
  final String id;
  String text;
  DateTime? dueDate;
  bool isCompleted;

  Task({
    required this.id,
    required this.text,
    this.dueDate,
    this.isCompleted = false,
  });
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final List<Task> _tasks = [];
  TaskFilters _selectedFilter = TaskFilters.today;

  @override
  void initState() {
    super.initState();
    _sortTasks();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _addTask(String text, DateTime? dueDate) {
    if (text.isNotEmpty) {
      setState(() {
        _tasks.add(
          Task(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: text,
            dueDate: dueDate,
          ),
        );
        _sortTasks();
      });
    }
  }

  Future<DateTime?> _pickDateTime(DateTime? initialDateTime) async {
    if (!context.mounted) return null;

    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (date == null) return null;

    if (!context.mounted) return null;

    final TimeOfDay? time = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime ?? DateTime.now()),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _sortTasks() {
    _tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      }
      return 0;
    });
  }

  void _toggleTaskComplete(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      setState(() {
        _tasks[index].isCompleted = !_tasks[index].isCompleted;
        _sortTasks();
      });
    }
  }

  void _removeTask(Task taskToRemove) {
    final actualIndex = _tasks.indexWhere((task) => task.id == taskToRemove.id);
    if (actualIndex != -1) {
      setState(() {
        _tasks.removeAt(actualIndex);
      });
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(Task task) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Are you sure you want to delete task "${task.text}"?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Delete"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddTaskDialog() async {
    final TextEditingController dialogTaskController = TextEditingController();
    DateTime? dialogSelectedDateTime;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              icon: const Icon(Icons.add_task),
              title: const Text("Add New Task"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    TextField(
                      controller: dialogTaskController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Task Description",
                        hintText: "Take out the trash",
                      ),
                      autofocus: true,
                      onSubmitted: (_) {
                        final String text = dialogTaskController.text.trim();
                        if (text.isNotEmpty) {
                          _addTask(text, dialogSelectedDateTime);
                          Navigator.of(dialogContext).pop();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dialogSelectedDateTime == null
                                ? "No due date set"
                                : "Due: ${DateFormat.yMd().add_jm().format(dialogSelectedDateTime!)}",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        if (dialogSelectedDateTime != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            tooltip: "Clear Date/Time",
                            onPressed:
                                () => setDialogState(
                                  () => dialogSelectedDateTime = null,
                                ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          tooltip: "Pick Due Date/Time",
                          onPressed: () async {
                            final pickedDateTime = await _pickDateTime(
                              dialogSelectedDateTime,
                            );
                            if (pickedDateTime != dialogSelectedDateTime) {
                              setDialogState(() {
                                dialogSelectedDateTime = pickedDateTime;
                              });
                            }
                          },
                          color:
                              dialogSelectedDateTime != null
                                  ? Theme.of(context).primaryColor
                                  : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(elevation: 0),
                  onPressed: () {
                    final String text = dialogTaskController.text.trim();
                    if (text.isNotEmpty) {
                      _addTask(text, dialogSelectedDateTime);
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Task> _getFilteredTasks() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedFilter) {
      case TaskFilters.today:
        return _tasks.where((task) {
          return !task.isCompleted &&
              task.dueDate != null &&
              task.dueDate!.isAfter(
                todayStart.subtract(const Duration(microseconds: 1)),
              ) &&
              task.dueDate!.isBefore(
                todayEnd.add(const Duration(microseconds: 1)),
              );
        }).toList();
      case TaskFilters.all:
        return _tasks.where((task) => !task.isCompleted).toList();
      case TaskFilters.done:
        return _tasks.where((task) => task.isCompleted).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _getFilteredTasks();

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              pinned: true,
              expandedHeight: 150.0,
              flexibleSpace: FlexibleSpaceBar(title: Text("Tasks")),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SegmentedButton<TaskFilters>(
                  segments: const [
                    ButtonSegment<TaskFilters>(
                      value: TaskFilters.today,
                      label: Text("Today"),
                      icon: Icon(Icons.today),
                    ),
                    ButtonSegment<TaskFilters>(
                      value: TaskFilters.all,
                      label: Text("All"),
                      icon: Icon(Icons.list),
                    ),
                    ButtonSegment<TaskFilters>(
                      value: TaskFilters.done,
                      label: Text("Done"),
                      icon: Icon(Icons.check_circle),
                    ),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (Set<TaskFilters> newSelection) {
                    setState(() {
                      _selectedFilter = newSelection.first;
                    });
                  },
                ),
              ),
            ),
            if (filteredTasks.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      _selectedFilter == TaskFilters.done
                          ? "No completed tasks."
                          : _selectedFilter == TaskFilters.today
                          ? "No tasks due today."
                          : "No upcoming tasks.",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              )
            else
              SliverList.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  final isCompleted = task.isCompleted;
                  final dueDateText =
                      task.dueDate != null
                          ? DateFormat.yMd().add_jm().format(task.dueDate!)
                          : null;

                  return Dismissible(
                    key: ValueKey(task.id),
                    background: Container(
                      color: isCompleted ? Colors.orange : Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            isCompleted ? Icons.undo : Icons.check_circle,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCompleted ? "Mark Active" : "Mark Done",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    secondaryBackground: Container(
                      color: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerRight,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "Delete",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.delete, color: Colors.white),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      final taskInMainList = _tasks.firstWhere(
                        (t) => t.id == task.id,
                        orElse: () => task,
                      );

                      if (direction == DismissDirection.endToStart) {
                        final bool? confirm =
                            await _showDeleteConfirmationDialog(taskInMainList);
                        return confirm ?? false;
                      } else if (direction == DismissDirection.startToEnd) {
                        _toggleTaskComplete(taskInMainList);
                        return false;
                      }
                      return false;
                    },
                    onDismissed: (direction) {
                      if (direction == DismissDirection.endToStart) {
                        final taskInMainList = _tasks.firstWhere(
                          (t) => t.id == task.id,
                          orElse: () => task,
                        );
                        _removeTask(taskInMainList);
                      }
                    },
                    child: ListTile(
                      title: Text(
                        task.text,
                        style: TextStyle(
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? Colors.grey : null,
                        ),
                      ),
                      subtitle:
                          dueDateText != null
                              ? Text(
                                "Due: $dueDateText",
                                style: TextStyle(
                                  color: isCompleted ? Colors.grey : null,
                                  fontSize: 12,
                                ),
                              )
                              : null,
                      leading: Icon(
                        isCompleted
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color:
                            isCompleted
                                ? Colors.green
                                : Theme.of(context).colorScheme.secondary,
                      ),
                      onTap: () {
                        final taskInMainList = _tasks.firstWhere(
                          (t) => t.id == task.id,
                          orElse: () => task,
                        );
                        _toggleTaskComplete(taskInMainList);
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        tooltip: "Add Task",
        child: const Icon(Icons.add),
      ),
    );
  }
}
