import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../graveyard/presentation/abandon_dialog.dart';
import '../models/project.dart';
import '../models/project_task.dart';
import 'log_decision_dialog.dart';
import 'projects_notifier.dart';

class ProjectWorkspaceScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectWorkspaceScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<ProjectWorkspaceScreen> createState() =>
      _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState
    extends ConsumerState<ProjectWorkspaceScreen> {
  final TextEditingController _newTaskController = TextEditingController();
  String _taskFilter = 'all'; // 'all', 'pending', 'completed'
  bool _isAddingTask = false;

  @override
  void dispose() {
    _newTaskController.dispose();
    super.dispose();
  }

  Future<void> _handleAddTask() async {
    final text = _newTaskController.text.trim();
    if (text.isEmpty || _isAddingTask) return;

    setState(() => _isAddingTask = true);
    try {
      await ref
          .read(projectsActionProvider.notifier)
          .addTask(projectId: widget.projectId, title: text);
      _newTaskController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add task: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingTask = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync =
        ref.watch(projectDetailProvider(widget.projectId));

    return Scaffold(
      backgroundColor: ReforgeColors.warmSurface,
      appBar: AppBar(
        backgroundColor: ReforgeColors.warmSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: ReforgeColors.deepSlate),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'Project Workspace',
          style: ReforgeTypography.screenTitle.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.invalidate(
                projectDetailProvider(widget.projectId)),
          ),
        ],
      ),
      body: projectAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ReforgeColors.forgeAccent),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertCircle,
                    size: 40, color: ReforgeColors.danger),
                const SizedBox(height: 12),
                const Text('Failed to load workspace',
                    style: ReforgeTypography.cardTitle),
                const SizedBox(height: 4),
                Text(error.toString(),
                    style: ReforgeTypography.meta,
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(
                      projectDetailProvider(widget.projectId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (project) => _buildWorkspaceContent(context, project),
      ),
    );
  }

  Widget _buildWorkspaceContent(BuildContext context, Project project) {
    final filteredTasks = project.tasks.where((t) {
      if (_taskFilter == 'pending') return !t.isCompleted;
      if (_taskFilter == 'completed') return t.isCompleted;
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------------------
          // 1. Status & Header Info Card
          // -------------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ReforgeColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: ReforgeColors.successBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  project.status.toUpperCase(),
                                  style: ReforgeTypography.badge.copyWith(
                                    color: ReforgeColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (project.startedAt != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Started ${DateFormat.MMMd().format(project.startedAt!)}',
                                  style: ReforgeTypography.meta,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            project.title,
                            style: ReforgeTypography.screenTitle.copyWith(
                              fontSize: 22,
                              color: ReforgeColors.deepSlate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (project.summary != null && project.summary!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    project.summary!,
                    style: ReforgeTypography.body.copyWith(
                      color: ReforgeColors.muted,
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(height: 1, color: ReforgeColors.border),
                const SizedBox(height: 14),

                // Progress Bar & Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MVP Tasks Progress',
                      style: ReforgeTypography.cardTitle.copyWith(fontSize: 13),
                    ),
                    Text(
                      '${project.completedTasksCount} / ${project.totalTasksCount} (${(project.taskProgress * 100).toInt()}%)',
                      style: ReforgeTypography.badge.copyWith(
                        color: ReforgeColors.forgeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: project.taskProgress,
                    minHeight: 8,
                    backgroundColor: ReforgeColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      ReforgeColors.forgeAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // -------------------------------------------------------------------
          // 2. Prominent MVP Scope Banner (Reforge Core Principle)
          // -------------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ReforgeColors.forgeAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: ReforgeColors.forgeAccent.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.target,
                      size: 18,
                      color: ReforgeColors.forgeAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MVP Scope Boundary',
                      style: ReforgeTypography.cardTitle.copyWith(
                        color: ReforgeColors.forgeAccent,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  (project.mvpScope != null && project.mvpScope!.isNotEmpty)
                      ? project.mvpScope!
                      : 'No explicit MVP scope boundary set. Keep feature creep out!',
                  style: ReforgeTypography.body.copyWith(
                    color: ReforgeColors.graphite,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // -------------------------------------------------------------------
          // 3. Task Checklist Header & Filters
          // -------------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Task Checklist',
                style: ReforgeTypography.sectionTitle.copyWith(fontSize: 17),
              ),
              Row(
                children: [
                  _buildFilterChip('all', 'All (${project.totalTasksCount})'),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                      'pending', 'Pending (${project.totalTasksCount - project.completedTasksCount})'),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                      'completed', 'Done (${project.completedTasksCount})'),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Add Task Input Box
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newTaskController,
                  style: ReforgeTypography.body,
                  onSubmitted: (_) => _handleAddTask(),
                  decoration: InputDecoration(
                    hintText: 'Add a new task...',
                    filled: true,
                    fillColor: ReforgeColors.cardSurface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: ReforgeColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: ReforgeColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: ReforgeColors.forgeAccent),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _isAddingTask ? null : _handleAddTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ReforgeColors.deepSlate,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isAddingTask
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.plus, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // -------------------------------------------------------------------
          // 4. Tasks List
          // -------------------------------------------------------------------
          if (filteredTasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ReforgeColors.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ReforgeColors.border),
              ),
              child: Column(
                children: [
                  Icon(
                    _taskFilter == 'completed'
                        ? LucideIcons.checkCircle2
                        : LucideIcons.listTodo,
                    size: 36,
                    color: ReforgeColors.subtle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _taskFilter == 'completed'
                        ? 'No completed tasks yet'
                        : 'No tasks in checklist',
                    style: ReforgeTypography.cardTitle.copyWith(
                      color: ReforgeColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add your first task above to start tracking progress.',
                    style: ReforgeTypography.meta,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredTasks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                return _buildTaskTile(context, task);
              },
            ),

          const SizedBox(height: 32),

          // -------------------------------------------------------------------
          // 5. Phase A5 Lifecycle & Decision Memory
          // -------------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lifecycle & Decision Memory',
                style: ReforgeTypography.sectionTitle.copyWith(fontSize: 16),
              ),
              TextButton.icon(
                onPressed: () => context.go('/projects/${widget.projectId}/memory'),
                icon: const Icon(LucideIcons.history, size: 16),
                label: const Text('View Timeline'),
                style: TextButton.styleFrom(
                  foregroundColor: ReforgeColors.forgeAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => LogDecisionDialog.show(
                    context,
                    projectId: widget.projectId,
                  ),
                  icon: const Icon(LucideIcons.bookmarkPlus, size: 18),
                  label: const Text('Log Decision'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ReforgeColors.deepSlate,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: ReforgeColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => AbandonDialog.show(context, project),
                  icon: const Icon(LucideIcons.ghost, size: 18, color: ReforgeColors.danger),
                  label: const Text('Abandon Project', style: TextStyle(color: ReforgeColors.danger)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: ReforgeColors.dangerBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _taskFilter == value;
    return InkWell(
      onTap: () => setState(() => _taskFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? ReforgeColors.deepSlate
              : ReforgeColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? ReforgeColors.deepSlate : ReforgeColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : ReforgeColors.muted,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTile(BuildContext context, ProjectTask task) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: ReforgeColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.isCompleted
              ? ReforgeColors.borderSubtle
              : ReforgeColors.border,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Checkbox(
          value: task.isCompleted,
          activeColor: ReforgeColors.forgeAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onChanged: (_) {
            ref.read(projectsActionProvider.notifier).toggleTaskStatus(
                  projectId: widget.projectId,
                  taskId: task.id,
                  isCompleted: !task.isCompleted,
                );
          },
        ),
        title: Text(
          task.title,
          style: ReforgeTypography.body.copyWith(
            decoration: task.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: task.isCompleted
                ? ReforgeColors.subtle
                : ReforgeColors.graphite,
            fontWeight: task.isCompleted ? FontWeight.normal : FontWeight.w500,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(LucideIcons.trash2, size: 18, color: ReforgeColors.subtle),
          onPressed: () {
            ref.read(projectsActionProvider.notifier).deleteTask(
                  projectId: widget.projectId,
                  taskId: task.id,
                );
          },
        ),
      ),
    );
  }
}
