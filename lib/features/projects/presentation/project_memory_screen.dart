import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/local_storage/offline_decisions_cache.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/project_decision.dart';
import 'log_decision_dialog.dart';
import 'projects_notifier.dart';

class ProjectMemoryScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectMemoryScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<ProjectMemoryScreen> createState() => _ProjectMemoryScreenState();
}

class _ProjectMemoryScreenState extends ConsumerState<ProjectMemoryScreen> {
  String _typeFilter = 'all'; // 'all', 'decision', 'blocker', 'note'
  String _categoryFilter = 'all'; // 'all' + any category string
  String _searchQuery = '';
  final _searchController = TextEditingController();

  static const List<String> _categories = [
    'all',
    'Architecture',
    'Database',
    'UI/UX',
    'Scope',
    'DevOps',
    'Other',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final decisionsAsync = ref.watch(projectDecisionsProvider(widget.projectId));
    final projectAsync = ref.watch(projectDetailProvider(widget.projectId));

    final projectTitle = projectAsync.when(
      data: (p) => p.title,
      loading: () => 'Project Workspace',
      error: (_, _) => 'Project Workspace',
    );

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
              context.go('/projects/${widget.projectId}');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Memory Timeline',
              style: ReforgeTypography.screenTitle.copyWith(fontSize: 18),
            ),
            Text(
              projectTitle,
              style: ReforgeTypography.meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Refresh Timeline',
            onPressed: () => ref.invalidate(projectDecisionsProvider(widget.projectId)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => LogDecisionDialog.show(context, projectId: widget.projectId),
        backgroundColor: ReforgeColors.deepSlate,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text('Log Decision'),
      ),
      body: decisionsAsync.when(
        loading: () {
          // Show cached data while loading to avoid blank screen
          final cached = OfflineDecisionsCache.loadDecisions(widget.projectId);
          if (cached.isNotEmpty) {
            return _buildBody(context, cached, isFromCache: true);
          }
          return const Center(child: CircularProgressIndicator(color: ReforgeColors.forgeAccent));
        },
        error: (error, _) {
          // Graceful offline fallback to cached data
          final cached = OfflineDecisionsCache.loadDecisions(widget.projectId);
          if (cached.isNotEmpty) {
            return _buildBody(context, cached, isFromCache: true, errorMessage: 'Showing cached data. Network error: ${error.toString().replaceAll('Exception: ', '')}');
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.alertCircle, size: 36, color: ReforgeColors.danger),
                  const SizedBox(height: 8),
                  const Text('Failed to load memory timeline', style: ReforgeTypography.cardTitle),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(projectDecisionsProvider(widget.projectId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (decisions) {
          // Cache fresh data locally for future offline use
          OfflineDecisionsCache.saveDecisions(widget.projectId, decisions);
          return _buildBody(context, decisions);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<ProjectDecision> decisions, {
    bool isFromCache = false,
    String? errorMessage,
  }) {
    // Apply filters
    final filtered = decisions.where((d) {
      final matchesType = _typeFilter == 'all' || d.entryType == _typeFilter;
      final matchesCategory = _categoryFilter == 'all' || d.category == _categoryFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          d.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.decision.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (d.rationale?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesType && matchesCategory && matchesSearch;
    }).toList();

    // Build counts for summary bar
    final decisionCount = decisions.where((d) => d.isDecision).length;
    final blockerCount = decisions.where((d) => d.isBlocker).length;
    final noteCount = decisions.where((d) => d.isNote).length;

    return Column(
      children: [
        // Offline cache banner
        if (isFromCache)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: ReforgeColors.warningBg,
            child: Row(
              children: [
                const Icon(LucideIcons.wifiOff, size: 14, color: ReforgeColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage ?? 'Showing cached timeline data (offline)',
                    style: ReforgeTypography.bodySmall.copyWith(color: ReforgeColors.warning),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),

        // Summary Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              _SummaryPill(icon: LucideIcons.checkCircle2, label: '$decisionCount Decisions', color: ReforgeColors.success),
              const SizedBox(width: 8),
              _SummaryPill(icon: LucideIcons.alertTriangle, label: '$blockerCount Blockers', color: ReforgeColors.danger),
              const SizedBox(width: 8),
              _SummaryPill(icon: LucideIcons.fileText, label: '$noteCount Notes', color: ReforgeColors.category),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: ReforgeTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search memory entries...',
              hintStyle: ReforgeTypography.body.copyWith(color: ReforgeColors.subtle),
              prefixIcon: const Icon(LucideIcons.search, size: 18, color: ReforgeColors.muted),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 16, color: ReforgeColors.muted),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: ReforgeColors.cardSurface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                borderSide: const BorderSide(color: ReforgeColors.forgeAccent, width: 1.5),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Type Filter Row
        SizedBox(
          height: 34,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('all', 'All Memory'),
                const SizedBox(width: 8),
                _buildFilterChip('decision', 'Decisions'),
                const SizedBox(width: 8),
                _buildFilterChip('blocker', 'Blockers'),
                const SizedBox(width: 8),
                _buildFilterChip('note', 'Notes'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Category Filter Row
        SizedBox(
          height: 32,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categories.map((cat) {
                final label = cat == 'all' ? 'All Categories' : cat;
                final isSelected = _categoryFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _categoryFilter = cat),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? ReforgeColors.category : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? ReforgeColors.category : ReforgeColors.border,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Colors.white : ReforgeColors.muted,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Timeline Body
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildTimelineItem(context, filtered[index], index == filtered.length - 1);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _typeFilter == value;
    return InkWell(
      onTap: () => setState(() => _typeFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? ReforgeColors.deepSlate : ReforgeColors.cardSurface,
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ReforgeColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ReforgeColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: ReforgeColors.warmSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.bookmarkPlus, size: 32, color: ReforgeColors.subtle),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _typeFilter != 'all' || _categoryFilter != 'all'
                  ? 'No matching memory entries'
                  : 'No Memory Logs Yet',
              style: ReforgeTypography.cardTitle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try clearing the search or changing filters.'
                  : 'Log decisions, technical blockers, and architectural choices to preserve project execution context.',
              style: ReforgeTypography.meta,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_searchQuery.isEmpty && _typeFilter == 'all' && _categoryFilter == 'all')
              ElevatedButton.icon(
                onPressed: () => LogDecisionDialog.show(context, projectId: widget.projectId),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Log First Decision'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ReforgeColors.deepSlate,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, ProjectDecision item, bool isLast) {
    Color typeColor;
    IconData typeIcon;
    String badgeLabel;

    if (item.isBlocker) {
      typeColor = ReforgeColors.danger;
      typeIcon = LucideIcons.alertTriangle;
      badgeLabel = 'BLOCKER';
    } else if (item.isDecision) {
      typeColor = ReforgeColors.success;
      typeIcon = LucideIcons.checkCircle2;
      badgeLabel = 'DECISION';
    } else {
      typeColor = ReforgeColors.category;
      typeIcon = LucideIcons.fileText;
      badgeLabel = 'NOTE';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Node & Bar
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: typeColor, width: 1.5),
                ),
                child: Icon(typeIcon, size: 14, color: typeColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: ReforgeColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ReforgeColors.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ReforgeColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeLabel,
                              style: ReforgeTypography.badge.copyWith(
                                color: typeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Category pill
                          if (item.category != 'Other') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: ReforgeColors.categoryBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: ReforgeColors.categoryBorder),
                              ),
                              child: Text(
                                item.category,
                                style: ReforgeTypography.badge.copyWith(
                                  color: ReforgeColors.category,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (item.createdAt != null)
                        Text(
                          DateFormat.yMMMd().add_jm().format(item.createdAt!),
                          style: ReforgeTypography.meta,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: ReforgeTypography.cardTitle.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.decision,
                    style: ReforgeTypography.body.copyWith(
                      color: ReforgeColors.graphite,
                      height: 1.45,
                    ),
                  ),
                  if (item.rationale != null && item.rationale!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ReforgeColors.warmSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ReforgeColors.borderSubtle),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.lightbulb, size: 14, color: ReforgeColors.forgeAccent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Rationale: ${item.rationale}',
                              style: ReforgeTypography.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SummaryPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
