// ignore_for_file: depend_on_referenced_packages

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TASK MODEL
// ─────────────────────────────────────────────────────────────────────────────

class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final bool isCompleted;

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [id, title, isCompleted];
}

// ─────────────────────────────────────────────────────────────────────────────
// TASK REPOSITORY
// ─────────────────────────────────────────────────────────────────────────────

class TaskRepository {
  final List<Task> _tasks = [];

  Future<List<Task>> fetchTasks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_tasks);
  }

  Future<void> addTask(Task task) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _tasks.add(task);
  }

  Future<void> updateTask(Task updated) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _tasks.indexWhere((t) => t.id == updated.id);
    if (index != -1) _tasks[index] = updated;
  }

  Future<void> deleteTask(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _tasks.removeWhere((t) => t.id == id);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BLOC LAYER — EVENTS
// ─────────────────────────────────────────────────────────────────────────────

abstract class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object?> get props => [];
}

class TodoLoadRequested extends TodoEvent {
  const TodoLoadRequested();
}

class TodoTaskAdded extends TodoEvent {
  const TodoTaskAdded(this.title);

  final String title;

  @override
  List<Object?> get props => [title];
}

class TodoTaskToggled extends TodoEvent {
  const TodoTaskToggled(this.task);

  final Task task;

  @override
  List<Object?> get props => [task];
}

class TodoTaskEdited extends TodoEvent {
  const TodoTaskEdited({required this.task, required this.newTitle});

  final Task task;
  final String newTitle;

  @override
  List<Object?> get props => [task, newTitle];
}

class TodoTaskDeleted extends TodoEvent {
  const TodoTaskDeleted(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

// ─────────────────────────────────────────────────────────────────────────────
// BLOC LAYER — STATES
// ─────────────────────────────────────────────────────────────────────────────

abstract class TodoState extends Equatable {
  const TodoState();

  @override
  List<Object?> get props => [];
}

class TodoInitial extends TodoState {
  const TodoInitial();
}

class TodoLoading extends TodoState {
  const TodoLoading();
}

class TodoLoaded extends TodoState {
  const TodoLoaded(this.tasks);

  final List<Task> tasks;

  @override
  List<Object?> get props => [tasks];
}

class TodoError extends TodoState {
  const TodoError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// ─────────────────────────────────────────────────────────────────────────────
// BLOC LAYER — BLOC
// ─────────────────────────────────────────────────────────────────────────────

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  TodoBloc({required TaskRepository repository})
      : _repository = repository,
        super(const TodoInitial()) {
    on<TodoLoadRequested>(_onLoadRequested);
    on<TodoTaskAdded>(_onTaskAdded);
    on<TodoTaskToggled>(_onTaskToggled);
    on<TodoTaskEdited>(_onTaskEdited);
    on<TodoTaskDeleted>(_onTaskDeleted);
  }

  final TaskRepository _repository;

  Future<void> _onLoadRequested(
      TodoLoadRequested event,
      Emitter<TodoState> emit,
      ) async {
    emit(const TodoLoading());
    try {
      final tasks = await _repository.fetchTasks();
      emit(TodoLoaded(tasks));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  Future<void> _onTaskAdded(
      TodoTaskAdded event,
      Emitter<TodoState> emit,
      ) async {
    try {
      final task = Task(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: event.title.trim(),
      );
      await _repository.addTask(task);
      final tasks = await _repository.fetchTasks();
      emit(TodoLoaded(tasks));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  Future<void> _onTaskToggled(
      TodoTaskToggled event,
      Emitter<TodoState> emit,
      ) async {
    try {
      final updated = event.task.copyWith(isCompleted: !event.task.isCompleted);
      await _repository.updateTask(updated);
      final tasks = await _repository.fetchTasks();
      emit(TodoLoaded(tasks));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  Future<void> _onTaskEdited(
      TodoTaskEdited event,
      Emitter<TodoState> emit,
      ) async {
    try {
      final updated = event.task.copyWith(title: event.newTitle.trim());
      await _repository.updateTask(updated);
      final tasks = await _repository.fetchTasks();
      emit(TodoLoaded(tasks));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  Future<void> _onTaskDeleted(
      TodoTaskDeleted event,
      Emitter<TodoState> emit,
      ) async {
    try {
      await _repository.deleteTask(event.taskId);
      final tasks = await _repository.fetchTasks();
      emit(TodoLoaded(tasks));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRESENTATION LAYER — ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => TaskRepository(),
      child: BlocProvider(
        create: (context) => TodoBloc(
          repository: context.read<TaskRepository>(),
        )..add(const TodoLoadRequested()),
        child: MaterialApp(
          title: 'To-Do',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          home: const TodoPage(),
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    const seedColor = Color(0xFF5B6AF0);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: seedColor, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRESENTATION LAYER — PAGE
// ─────────────────────────────────────────────────────────────────────────────

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final _addController = TextEditingController();
  final _addFocusNode = FocusNode();

  @override
  void dispose() {
    _addController.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }

  void _submitAdd() {
    final title = _addController.text.trim();
    if (title.isEmpty) return;
    context.read<TodoBloc>().add(TodoTaskAdded(title));
    _addController.clear();
    _addFocusNode.requestFocus();
  }

  Future<void> _showEditDialog(Task task) async {
    final controller = TextEditingController(text: task.title);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Task title'),
          onSubmitted: (_) => Navigator.of(ctx).pop(true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      if (mounted) {
        context
            .read<TodoBloc>()
            .add(TodoTaskEdited(task: task, newTitle: controller.text));
      }
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: const Text(
          'My Tasks',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
      ),
      body: Column(
        children: [
          _AddTaskBar(
            controller: _addController,
            focusNode: _addFocusNode,
            onSubmit: _submitAdd,
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<TodoBloc, TodoState>(
              builder: (context, state) {
                return switch (state) {
                  TodoInitial() || TodoLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  TodoError(:final message) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent)),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context
                              .read<TodoBloc>()
                              .add(const TodoLoadRequested()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  TodoLoaded(:final tasks) when tasks.isEmpty => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 64, color: colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text(
                          'No tasks yet.\nAdd one above to get started.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  TodoLoaded(:final tasks) => ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _TaskTile(
                        task: task,
                        onToggle: () => context
                            .read<TodoBloc>()
                            .add(TodoTaskToggled(task)),
                        onEdit: () => _showEditDialog(task),
                        onDelete: () => context
                            .read<TodoBloc>()
                            .add(TodoTaskDeleted(task.id)),
                      );
                    },
                  ),
                  _ => const SizedBox.shrink(),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRESENTATION LAYER — WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _AddTaskBar extends StatelessWidget {
  const _AddTaskBar({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(
                hintText: 'New task…',
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onSubmit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompleted = task.isCompleted;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Checkbox(
        value: isCompleted,
        onChanged: (_) => onToggle(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          fontSize: 15,
          decoration: isCompleted ? TextDecoration.lineThrough : null,
          color: isCompleted ? colorScheme.onSurfaceVariant : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Edit',
            color: colorScheme.primary,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Delete',
            color: colorScheme.error,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}