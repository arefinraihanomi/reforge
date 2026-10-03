import 'package:flutter/foundation.dart';
import '../models/project.dart';

@immutable
class AnalyticsSummary {
  final int totalProjects;
  final int activeProjects;
  final int completedProjects;
  final int abandonedProjects;
  final double completionRate;
  final double avgTaskCompletionRate;
  final Map<String, int> abandonmentReasons; // 'scope_creep': 3, 'technical_blocker': 2, etc.
  final Map<String, int> projectStatusCounts;

  const AnalyticsSummary({
    required this.totalProjects,
    required this.activeProjects,
    required this.completedProjects,
    required this.abandonedProjects,
    required this.completionRate,
    required this.avgTaskCompletionRate,
    required this.abandonmentReasons,
    required this.projectStatusCounts,
  });

  factory AnalyticsSummary.fromProjects(List<Project> projects) {
    if (projects.isEmpty) {
      return const AnalyticsSummary(
        totalProjects: 0,
        activeProjects: 0,
        completedProjects: 0,
        abandonedProjects: 0,
        completionRate: 0.0,
        avgTaskCompletionRate: 0.0,
        abandonmentReasons: {},
        projectStatusCounts: {},
      );
    }

    int active = 0;
    int completed = 0;
    int abandoned = 0;
    double totalTaskProgressSum = 0.0;
    int projectsWithTasks = 0;
    final Map<String, int> reasons = {};
    final Map<String, int> statusCounts = {};

    for (final p in projects) {
      statusCounts[p.status] = (statusCounts[p.status] ?? 0) + 1;

      if (p.isActive) {
        active++;
      } else if (p.isCompleted) {
        completed++;
      } else if (p.isAbandoned) {
        abandoned++;
        final reason = p.abandonReason ?? 'other';
        reasons[reason] = (reasons[reason] ?? 0) + 1;
      }

      if (p.tasks.isNotEmpty) {
        totalTaskProgressSum += p.taskProgress;
        projectsWithTasks++;
      }
    }

    final double completionRate =
        (completed + abandoned) > 0 ? (completed / (completed + abandoned)) * 100 : 0.0;

    final double avgTaskProgress =
        projectsWithTasks > 0 ? (totalTaskProgressSum / projectsWithTasks) * 100 : 0.0;

    return AnalyticsSummary(
      totalProjects: projects.length,
      activeProjects: active,
      completedProjects: completed,
      abandonedProjects: abandoned,
      completionRate: completionRate,
      avgTaskCompletionRate: avgTaskProgress,
      abandonmentReasons: reasons,
      projectStatusCounts: statusCounts,
    );
  }
}
