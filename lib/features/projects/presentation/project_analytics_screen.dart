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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ReforgeColors.deepSlate.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.barChart2, size: 48, color: ReforgeColors.graphite),
              ),
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

    final isDesktop = MediaQuery.of(context).size.width > 700;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // Summary Header Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ReforgeColors.deepSlate,
                ReforgeColors.deepSlate.withValues(alpha: 0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ReforgeColors.forgeAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.activity,
                  color: ReforgeColors.forgeAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Engineering Health Pulse',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tracking ${summary.totalProjects} total projects with ${(summary.completionRate * 100).toStringAsFixed(0)}% completion rate',
                      style: const TextStyle(
                        color: ReforgeColors.subtle,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Text('Lifecycle Metrics', style: ReforgeTypography.sectionTitle),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: isDesktop ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isDesktop ? 1.4 : 1.25,
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
              title: 'Active Builds',
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

        Text('Execution Rates', style: ReforgeTypography.sectionTitle),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: ReforgeColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ReforgeColors.border),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _ProgressIndicatorRow(
                label: 'Project Completion Rate',
                percentage: summary.completionRate,
                color: ReforgeColors.success,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: ReforgeColors.border),
              ),
              _ProgressIndicatorRow(
                label: 'Avg Task Execution Rate',
                percentage: summary.avgTaskCompletionRate,
                color: ReforgeColors.forgeAccent,
              ),
            ],
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
          Container(
            decoration: BoxDecoration(
              color: ReforgeColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ReforgeColors.border),
            ),
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: ReforgeColors.successBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.smile, color: ReforgeColors.success, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'No abandoned projects recorded yet! Keep forging forward.',
                    style: ReforgeTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: ReforgeColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ReforgeColors.border),
            ),
            padding: const EdgeInsets.all(20.0),
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
                            style: ReforgeTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: ReforgeColors.warmSurface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: ReforgeColors.border),
                            ),
                            child: Text(
                              '$count project${count > 1 ? 's' : ''} (${(pct * 100).toStringAsFixed(0)}%)',
                              style: ReforgeTypography.badge.copyWith(
                                color: ReforgeColors.graphite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: ReforgeColors.warmSurface,
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
