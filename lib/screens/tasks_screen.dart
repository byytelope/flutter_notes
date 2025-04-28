import "package:flutter/material.dart";
import "package:hive_ce_flutter/hive_flutter.dart";
import "package:intl/intl.dart";
import "package:uuid/uuid.dart";

import "package:flutter_notes/models/task.dart";

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => TasksScreenState();
}

class TasksScreenState extends State<TasksScreen> {
  TaskFilter _selectedFilter = TaskFilter.today;
  final _box = Hive.box<Task>("tasks");
  final _prefsBox = Hive.box("user_preferences");
  final _uuid = const Uuid();

  void _addTask(String text, DateTime? dueDate) async {
    if (text.isNotEmpty) {
      final id = _uuid.v4();
      final newTask = Task(id: id, text: text, dueDate: dueDate);

      await _box.put(id, newTask);
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

  void _toggleTaskComplete(Task task) async {
    task.isCompleted = !task.isCompleted;
    await task.save();
  }

  void _removeTask(Task task) async {
    await task.delete();
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

  Future<void> showAddTaskDialog() async {
    final TextEditingController dialogTaskController = TextEditingController();
    DateTime? dialogSelectedDateTime;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final mediaQuery = MediaQuery.of(context);
        final height = mediaQuery.size.height;
        final width = mediaQuery.size.width;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              icon: const Icon(Icons.add_task),
              title: const Text("Add New Task"),
              content: SizedBox(
                height: height * 0.2,
                width: width * 0.8,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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

  @override
  void initState() {
    super.initState();
    _selectedFilter =
        TaskFilter.values[_prefsBox.get(
          "default_task_filter",
          defaultValue: 0,
        )];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              pinned: true,
              expandedHeight: 150.0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text("Tasks"),
                centerTitle: true,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SegmentedButton<TaskFilter>(
                  segments: const [
                    ButtonSegment<TaskFilter>(
                      value: TaskFilter.today,
                      label: Text("Today"),
                      icon: Icon(Icons.today),
                    ),
                    ButtonSegment<TaskFilter>(
                      value: TaskFilter.all,
                      label: Text("All"),
                      icon: Icon(Icons.list),
                    ),
                    ButtonSegment<TaskFilter>(
                      value: TaskFilter.done,
                      label: Text("Done"),
                      icon: Icon(Icons.check_circle),
                    ),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (Set<TaskFilter> newSelection) {
                    setState(() {
                      _selectedFilter = newSelection.first;
                    });
                  },
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: _box.listenable(),
              builder: (context, box, _) {
                final now = DateTime.now();
                final todayStart = DateTime(now.year, now.month, now.day);
                final todayEnd = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  23,
                  59,
                  59,
                );
                List<Task> allTasks = box.values.toList();
                allTasks.sort((a, b) {
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
                  return a.text.compareTo(b.text);
                });

                List<Task> filteredTasks;

                switch (_selectedFilter) {
                  case TaskFilter.today:
                    filteredTasks =
                        allTasks.where((task) {
                          return !task.isCompleted &&
                              task.dueDate != null &&
                              task.dueDate!.isAfter(
                                todayStart.subtract(
                                  const Duration(microseconds: 1),
                                ),
                              ) &&
                              task.dueDate!.isBefore(
                                todayEnd.add(const Duration(microseconds: 1)),
                              );
                        }).toList();
                    break;
                  case TaskFilter.all:
                    filteredTasks =
                        allTasks.where((task) => !task.isCompleted).toList();
                    break;
                  case TaskFilter.done:
                    filteredTasks =
                        allTasks.where((task) => task.isCompleted).toList();
                    break;
                }

                return filteredTasks.isEmpty
                    ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            _selectedFilter == TaskFilter.done
                                ? "No completed tasks."
                                : _selectedFilter == TaskFilter.today
                                ? "No tasks due today."
                                : "No upcoming tasks.",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    )
                    : SliverList.builder(
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        final isCompleted = task.isCompleted;
                        final dueDateText =
                            task.dueDate != null
                                ? DateFormat.yMd().add_jm().format(
                                  task.dueDate!,
                                )
                                : null;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          child: Dismissible(
                            key: ValueKey(task.id),
                            background: Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color:
                                    isCompleted
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.secondary
                                        : Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    isCompleted
                                        ? Icons.undo
                                        : Icons.check_circle_outline,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isCompleted ? "Mark Active" : "Mark Done",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            secondaryBackground: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "Delete",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.onError,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.delete_outline,
                                    color:
                                        Theme.of(context).colorScheme.onError,
                                  ),
                                ],
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                final bool confirmDeletions = _prefsBox.get(
                                  "confirm_deletions",
                                  defaultValue: true,
                                );
                                if (confirmDeletions) {
                                  final bool? confirm =
                                      await _showDeleteConfirmationDialog(task);
                                  return confirm ?? false;
                                }
                                return true;
                              } else if (direction ==
                                  DismissDirection.startToEnd) {
                                _toggleTaskComplete(task);
                                return false;
                              }
                              return false;
                            },
                            onDismissed: (direction) {
                              if (direction == DismissDirection.endToStart) {
                                _removeTask(task);
                              }
                            },
                            child: Material(
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                tileColor:
                                    Theme.of(
                                      context,
                                    ).colorScheme.secondaryContainer,
                                title: Text(
                                  task.text,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(
                                    decoration:
                                        isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                    color:
                                        isCompleted
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.outline
                                            : null,
                                  ),
                                ),
                                subtitle:
                                    dueDateText != null
                                        ? Text(
                                          "Due: $dueDateText",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.copyWith(
                                            color:
                                                isCompleted
                                                    ? Theme.of(
                                                      context,
                                                    ).colorScheme.outline
                                                    : null,
                                          ),
                                        )
                                        : null,
                                leading: Icon(
                                  isCompleted
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color:
                                      isCompleted
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primary
                                          : Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                ),
                                onTap: () {
                                  _toggleTaskComplete(task);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}
