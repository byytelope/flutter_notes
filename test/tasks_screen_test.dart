import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:widget_training/screens/tasks_screen.dart";

void main() {
  Future<void> pumpTasksScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TasksScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> addTask(
    WidgetTester tester,
    String description, {
    DateTime? dueDate,
  }) async {
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, "Task Description"),
      description,
    );
    await tester.pump();

    if (dueDate != null) {
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      await tester.tap(find.text(dueDate.day.toString()));
      await tester.pumpAndSettle();

      await tester.tap(find.text("OK"));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.widgetWithText(ElevatedButton, "Add"));
    await tester.pumpAndSettle();
  }

  testWidgets("TasksScreen renders initial state correctly", (
    WidgetTester tester,
  ) async {
    await pumpTasksScreen(tester);

    expect(find.text("Tasks"), findsOneWidget);
    expect(find.byType(SegmentedButton<TaskFilters>), findsOneWidget);
    expect(find.text("Today"), findsOneWidget);
    expect(find.text("All"), findsOneWidget);
    expect(find.text("Done"), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets("Add Task Dialog opens and adds a task for today", (
    WidgetTester tester,
  ) async {
    await pumpTasksScreen(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text("Add New Task"), findsOneWidget);
    expect(find.widgetWithText(TextField, "Task Description"), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today), findsOneWidget);

    const String taskText = "Test Task 1";
    await tester.enterText(
      find.widgetWithText(TextField, "Task Description"),
      taskText,
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, "Add"));
    await tester.pumpAndSettle();

    expect(find.text("Add New Task"), findsNothing);
    expect(find.text(taskText), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
  });

  testWidgets("Tapping a task toggles its completion status", (
    WidgetTester tester,
  ) async {
    await pumpTasksScreen(tester);
    const String taskText = "Toggle Task";
    await addTask(tester, taskText);

    expect(find.text(taskText), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    expect(find.byIcon(Icons.check_box), findsNothing);

    await tester.tap(find.text(taskText));
    await tester.pumpAndSettle();

    // Task should move to completed section, potentially invisible in 'Today'
    // Switch filter to 'Done' to see it
    await tester.tap(find.text("Done"));
    await tester.pumpAndSettle();

    expect(find.text(taskText), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsNothing);
    expect(find.byIcon(Icons.check_box), findsOneWidget);

    // Tap again to mark incomplete
    await tester.tap(find.text(taskText));
    await tester.pumpAndSettle();

    // Switch filter back to 'Today' to see it
    await tester.tap(find.text("Today"));
    await tester.pumpAndSettle();

    expect(find.text(taskText), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    expect(find.byIcon(Icons.check_box), findsNothing);
  });

  testWidgets("Swiping task right marks it complete/active", (
    WidgetTester tester,
  ) async {
    await pumpTasksScreen(tester);
    const String taskText = "Swipe Complete Task";
    await addTask(tester, taskText);

    final taskFinder = find.widgetWithText(Dismissible, taskText);
    expect(taskFinder, findsOneWidget);

    await tester.drag(taskFinder, const Offset(300.0, 0.0));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Done"));
    await tester.pumpAndSettle();
    expect(find.text(taskText), findsOneWidget);
    expect(find.byIcon(Icons.check_box), findsOneWidget);

    final completedTaskFinder = find.widgetWithText(Dismissible, taskText);
    await tester.drag(completedTaskFinder, const Offset(300.0, 0.0));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Today"));
    await tester.pumpAndSettle();
    expect(find.text(taskText), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
  });

  testWidgets("Swiping task left deletes it after confirmation", (
    WidgetTester tester,
  ) async {
    await pumpTasksScreen(tester);
    const String taskText = "Delete Task";
    await addTask(tester, taskText);

    final taskFinder = find.widgetWithText(Dismissible, taskText);
    expect(taskFinder, findsOneWidget);

    await tester.drag(taskFinder, const Offset(-300.0, 0.0));
    await tester.pumpAndSettle();

    expect(find.text("Confirm Delete"), findsOneWidget);
    expect(
      find.text('Are you sure you want to delete task "$taskText"?'),
      findsOneWidget,
    );

    await tester.tap(find.text("Cancel"));
    await tester.pumpAndSettle();
    expect(find.text(taskText), findsOneWidget);

    await tester.drag(taskFinder, const Offset(-300.0, 0.0));
    await tester.pumpAndSettle();
    expect(find.text("Confirm Delete"), findsOneWidget);

    await tester.tap(find.text("Delete"));
    await tester.pumpAndSettle();
    expect(find.text(taskText), findsNothing);
  });

  testWidgets("Filtering tasks works correctly", (WidgetTester tester) async {
    await pumpTasksScreen(tester);
    final DateTime today = DateTime.now();
    final DateTime tomorrow = today.add(const Duration(days: 1));

    // Add tasks
    const String taskTodayIncomplete = "Task Today Incomplete";
    const String taskTodayComplete = "Task Today Complete";
    const String taskTomorrowIncomplete = "Task Tomorrow Incomplete";
    const String taskTomorrowComplete = "Task Tomorrow Complete";

    await addTask(tester, taskTodayIncomplete, dueDate: today);
    await addTask(tester, taskTodayComplete, dueDate: today);
    await addTask(tester, taskTomorrowIncomplete, dueDate: tomorrow);
    await addTask(tester, taskTomorrowComplete, dueDate: tomorrow);

    // Mark some as complete
    await tester.tap(find.text(taskTodayComplete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(taskTomorrowComplete));
    await tester.pumpAndSettle();

    // Test 'Today' Filter (Default)
    expect(find.text(taskTodayIncomplete), findsOneWidget);
    expect(find.text(taskTodayComplete), findsOneWidget);
    expect(find.text(taskTomorrowIncomplete), findsNothing);
    expect(find.text(taskTomorrowComplete), findsNothing);

    // Test 'All' Filter
    await tester.tap(find.text("All"));
    await tester.pumpAndSettle();
    expect(find.text(taskTodayIncomplete), findsOneWidget);
    expect(find.text(taskTodayComplete), findsOneWidget);
    expect(find.text(taskTomorrowIncomplete), findsOneWidget);
    expect(find.text(taskTomorrowComplete), findsOneWidget);

    // Test 'Done' Filter
    await tester.tap(find.text("Done"));
    await tester.pumpAndSettle();
    expect(find.text(taskTodayIncomplete), findsNothing);
    expect(find.text(taskTodayComplete), findsOneWidget);
    expect(find.text(taskTomorrowIncomplete), findsNothing);
    expect(find.text(taskTomorrowComplete), findsOneWidget);
  });

  testWidgets("Adding task with a future date works", (
    WidgetTester tester,
  ) async {
    await pumpTasksScreen(tester);
    final DateTime tomorrow = DateTime.now().add(const Duration(days: 1));

    const String futureTask = "Future Task";
    await addTask(tester, futureTask, dueDate: tomorrow);

    // Should not be visible in 'Today' filter
    expect(find.text(futureTask), findsNothing);

    // Should be visible in 'All' filter
    await tester.tap(find.text("All"));
    await tester.pumpAndSettle();
    expect(find.text(futureTask), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
  });

  testWidgets("Tasks are sorted correctly (incomplete first, then complete)", (
    WidgetTester tester,
  ) async {
    await pumpTasksScreen(tester);

    // Add tasks out of order
    const String taskB = "Task B - Incomplete";
    const String taskA = "Task A - Complete";
    const String taskC = "Task C - Incomplete";

    await addTask(tester, taskB);
    await addTask(tester, taskA);
    await addTask(tester, taskC);

    // Mark taskA complete
    await tester.tap(find.text(taskA));
    await tester.pumpAndSettle();

    // Switch to 'All' to see sorting of both types
    await tester.tap(find.text("All"));
    await tester.pumpAndSettle();

    // Find all task tiles (ListTile is assumed)
    final taskTiles = tester.widgetList<ListTile>(find.byType(ListTile));

    // Extract text from titles (assuming title is a Text widget)
    final taskTexts =
        taskTiles
            .map((tile) => (tile.title as Text).data)
            .whereType<String>()
            .toList();

    // Expected order: Incomplete (B, C), Complete (A)
    expect(taskTexts.contains(taskB), isTrue);
    expect(taskTexts.contains(taskC), isTrue);
    expect(taskTexts.contains(taskA), isTrue);

    // Verify relative order: Incomplete tasks appear before the complete task
    final indexB = taskTexts.indexOf(taskB);
    final indexC = taskTexts.indexOf(taskC);
    final indexA = taskTexts.indexOf(taskA);

    expect(indexB, lessThan(indexA));
    expect(indexC, lessThan(indexA));
  });
}
