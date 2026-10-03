import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/analytics_summary.dart';
import 'projects_notifier.dart';

/// Computed provider that extracts analytics metrics from the user's project history.
final projectAnalyticsProvider = FutureProvider.autoDispose<AnalyticsSummary>((ref) async {
  final projects = await ref.watch(projectsListProvider.future);
  return AnalyticsSummary.fromProjects(projects);
});

/// Health & Analytics Dashboard Screen displaying project metrics and abandonment breakdown.
class ProjectAnalyticsScreen extends ConsumerWidget {
  const ProjectAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(projectAnalyticsProvider);

    return Scaffold(
      backgroundColor: ReforgeColors.warmSurface,
      appBar: AppBar(
        backgroundColor: ReforgeColors.warmSurface,
        elevation: 0,
        title: Text(
          'Project Analytics',
          style: ReforgeTypography.screenTitle.copyWith(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: ReforgeColors.deepSlate),
            tooltip: 'Refresh Metrics',
            onPressed: () => ref.invalidate(projectAnalyticsProvider),
          ),
        ],
      ),
      body: analyticsAsync.when(
        data: (summary) => _buildAnalyticsBody(context, summary),
        loading: () => const Center(
          child: CircularProgressIndicator(color: ReforgeColors.forgeAccent),
        ),
        error: (err, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertTriangle, color: ReforgeColors.danger, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load analytics data',
                  style: ReforgeTypography.cardTitle,
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  style: ReforgeTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsBody(BuildContext context, AnalyticsSummary summary) {
    if (summary.totalProjects == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.barChart2, size: 64, color: ReforgeColors.subtle),
              const SizedBox(height: 16),
              Text('No Projects Found', style: ReforgeTypography.sectionTitle),
              const SizedBox(height: 8),
              Text(
                'Convert ideas into projects or start building to unlock project health metrics and abandonment analytics.',
                style: ReforgeTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Lifecycle Metrics', style: ReforgeTypography.sectionTitle),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _MetricCard(
              title: 'Total Projects',
              value: '${summary.totalProjects}',
              icon: LucideIcons.folder,
              accentColor: ReforgeColors.deepSlate,
            ),
            _MetricCard(
              title: 'Active',
              value: '${summary.activeProjects}',
              icon: LucideIcons.hammer,
              accentColor: ReforgeColors.forgeAccent,
            ),
            _MetricCard(
              title: 'Completed',
              value: '${summary.completedProjects}',
              icon: LucideIcons.checkCircle2,
              accentColor: ReforgeColors.success,
            ),
            _MetricCard(
              title: 'Abandoned',
              value: '${summary.abandonedProjects}',
              icon: LucideIcons.ghost,
              accentColor: ReforgeColors.danger,
            ),
          ],
        ),
        const SizedBox(height: 24),

        Text('Completion Rates', style: ReforgeTypography.sectionTitle),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: ReforgeColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _ProgressIndicatorRow(
                  label: 'Project Completion Rate',
                  percentage: summary.completionRate,
                  color: ReforgeColors.success,
                ),
                const Divider(height: 24),
                _ProgressIndicatorRow(
                  label: 'Avg MVP Task Execution',
                  percentage: summary.avgTaskCompletionRate,
                  color: ReforgeColors.forgeAccent,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        Text('Abandonment Drivers', style: ReforgeTypography.sectionTitle),
        const SizedBox(height: 4),
        const Text(
          'Primary reasons projects were paused or moved to the Graveyard.',
          style: ReforgeTypography.bodySmall,
        ),
        const SizedBox(height: 12),
        if (summary.abandonmentReasons.isEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: ReforgeColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const Icon(LucideIcons.smile, color: ReforgeColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No abandoned projects recorded yet! Keep forging forward.',
                      style: ReforgeTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: ReforgeColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: summary.abandonmentReasons.entries.map((entry) {
                  final reasonName = _formatReason(entry.key);
                  final count = entry.value;
                  final pct = summary.abandonedProjects > 0
                      ? count / summary.abandonedProjects
                      : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              reasonName,
                              style: ReforgeTypography.bodyMedium,
                            ),
                            Text(
                              '$count project${count > 1 ? 's' : ''} (${(pct * 100).toStringAsFixed(0)}%)',
                              style: ReforgeTypography.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor: ReforgeColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getReasonColor(entry.key),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  String _formatReason(String key) {
    switch (key) {
      case 'scope_creep':
        return 'Scope Creep';
      case 'technical_blocker':
        return 'Technical Blocker';
      case 'shifted_interest':
        return 'Shifted Focus / Interest';
      case 'time_constraint':
        return 'Time Constraints';
      default:
        return key.replaceAll('_', ' ').trim().isEmpty ? 'Other' : key.replaceAll('_', ' ');
    }
  }

  Color _getReasonColor(String key) {
    switch (key) {
      case 'scope_creep':
        return ReforgeColors.danger;
      case 'technical_blocker':
        return ReforgeColors.warning;
      case 'shifted_interest':
        return ReforgeColors.category;
      case 'time_constraint':
        return ReforgeColors.forgeAccent;
      default:
        return ReforgeColors.deepSlate;
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: ReforgeColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ReforgeColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: ReforgeTypography.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 18, color: accentColor),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: accentColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressIndicatorRow extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;

  const _ProgressIndicatorRow({
    required this.label,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: ReforgeTypography.bodyMedium),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: ReforgeColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
