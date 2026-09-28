import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/idea.dart';
import '../models/tag.dart';
import 'idea_detail_screen.dart';
import 'ideas_notifier.dart';

/// Main Idea Vault screen displaying the list of ideas with search, filters, and stats.
class IdeaVaultScreen extends ConsumerStatefulWidget {
  const IdeaVaultScreen({super.key});

  @override
  ConsumerState<IdeaVaultScreen> createState() => _IdeaVaultScreenState();
}

class _IdeaVaultScreenState extends ConsumerState<IdeaVaultScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ideasAsync = ref.watch(ideasListProvider);
    final stats = ref.watch(ideasStatsProvider);
    final filter = ref.watch(ideasFilterProvider);
    final tagsAsync = ref.watch(tagsListProvider);

    return Scaffold(
      backgroundColor: ReforgeColors.warmSurface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Stage Breadcrumb ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: ReforgeColors.forgeAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'STAGE 01: CAPTURE',
                    style: ReforgeTypography.overline.copyWith(
                      color: ReforgeColors.forgeAccent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Ideas',
                    style: ReforgeTypography.overline.copyWith(
                      fontWeight: FontWeight.w800,
                      color: ReforgeColors.graphite,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('→', style: ReforgeTypography.meta),
                  const SizedBox(width: 8),
                  Text('Build', style: ReforgeTypography.meta),
                  const SizedBox(width: 8),
                  Text('→', style: ReforgeTypography.meta),
                  const SizedBox(width: 8),
                  Text('Reflect', style: ReforgeTypography.meta),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- Title + Capture Button ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ideas Vault',
                          style: ReforgeTypography.screenTitle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Raw concepts, hypotheses &\nsparks waiting to be forged.',
                          style: ReforgeTypography.body,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showCaptureIdeaSheet(context),
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: const Text('Capture Idea'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ReforgeColors.forgeAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: ReforgeTypography.buttonPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- Stats Row ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: stats.when(
                data: (s) => _StatsRow(
                  totalSparks: s.totalSparks,
                  activeForge: s.activeForge,
                ),
                loading: () => const _StatsRow(totalSparks: 0, activeForge: 0),
                error: (_, _) =>
                    const _StatsRow(totalSparks: 0, activeForge: 0),
              ),
            ),

            const SizedBox(height: 16),

            // --- Search Bar ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    ref.read(ideasFilterProvider.notifier).setSearchQuery(v),
                style: ReforgeTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search ideas, tags, technical sparks...',
                  hintStyle: ReforgeTypography.body.copyWith(
                    color: ReforgeColors.subtle,
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    size: 20,
                    color: ReforgeColors.muted,
                  ),
                  suffixIcon: const Icon(
                    LucideIcons.mic,
                    size: 20,
                    color: ReforgeColors.muted,
                  ),
                  filled: true,
                  fillColor: ReforgeColors.cardSurface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ReforgeColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ReforgeColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: ReforgeColors.forgeAccent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- Filter Chips (Status + Tags) ---
            SizedBox(
              height: 36,
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // "All" chip
                    _FilterChip(
                      label:
                          ideasAsync.whenOrNull(
                            data: (ideas) => 'All (${ideas.length})',
                          ) ??
                          'All',
                      isSelected:
                          filter.status == null &&
                          filter.selectedTagIds.isEmpty,
                      onTap: () =>
                          ref.read(ideasFilterProvider.notifier).clearAll(),
                    ),
                    const SizedBox(width: 8),
                    // Status chips
                    for (final status in [
                      IdeaStatus.active,
                      IdeaStatus.exploring,
                      IdeaStatus.building,
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: status.label,
                          isSelected: filter.status == status,
                          onTap: () => ref
                              .read(ideasFilterProvider.notifier)
                              .setStatus(status),
                        ),
                      ),
                    // Tag chips
                    tagsAsync.whenOrNull(
                          data: (tags) => Row(
                            children: tags.map((tag) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _FilterChip(
                                  label: tag.name,
                                  isSelected: filter.selectedTagIds.contains(
                                    tag.id,
                                  ),
                                  onTap: () => ref
                                      .read(ideasFilterProvider.notifier)
                                      .toggleTag(tag.id),
                                ),
                              );
                            }).toList(),
                          ),
                        ) ??
                        const SizedBox.shrink(),
                    // Settings icon at the end
                    GestureDetector(
                      onTap: () {}, // Future: advanced filter sheet
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: ReforgeColors.cardSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ReforgeColors.border),
                        ),
                        child: const Icon(
                          LucideIcons.slidersHorizontal,
                          size: 16,
                          color: ReforgeColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- Ideas List ---
            Expanded(
              child: ideasAsync.when(
                data: (ideas) {
                  if (ideas.isEmpty) return const _EmptyVaultState();
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: ideas.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _IdeaCard(
                        idea: ideas[index],
                        onTap: () => _navigateToDetail(ideas[index].id),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: ReforgeColors.forgeAccent,
                  ),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.alertTriangle,
                          size: 48,
                          color: ReforgeColors.danger,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load ideas',
                          style: ReforgeTypography.cardTitle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: ReforgeTypography.body,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => ref.invalidate(ideasListProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCaptureIdeaSheet(context),
        backgroundColor: ReforgeColors.forgeAccent,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  void _navigateToDetail(String ideaId) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => IdeaDetailScreen(ideaId: ideaId)));
  }

  void _showCaptureIdeaSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ReforgeColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _QuickCaptureSheet(),
    );
  }
}

// =============================================================================
// Private Widgets
// =============================================================================

/// Stats row: Total Sparks | Active Forge | Velocity
class _StatsRow extends StatelessWidget {
  final int totalSparks;
  final int activeForge;

  const _StatsRow({required this.totalSparks, required this.activeForge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ReforgeColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ReforgeColors.border),
      ),
      child: Row(
        children: [
          _StatItem(label: 'Total Sparks', value: '$totalSparks'),
          const _StatDivider(),
          _StatItem(
            label: 'Active Forge',
            value: '$activeForge',
            valueColor: ReforgeColors.forgeAccent,
          ),
          const _StatDivider(),
          _StatItem(
            label: 'Velocity',
            value: '+${totalSparks > 0 ? (totalSparks / 4).ceil() : 0}/wk',
            valueColor: ReforgeColors.success,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: ReforgeTypography.statLabel),
          const SizedBox(height: 2),
          Text(
            value,
            style: ReforgeTypography.statNumber.copyWith(
              fontSize: 22,
              color: valueColor ?? ReforgeColors.graphite,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: ReforgeColors.border);
  }
}

/// Horizontal filter chip.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? ReforgeColors.graphite
              : ReforgeColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? ReforgeColors.graphite : ReforgeColors.border,
          ),
        ),
        child: Text(
          label,
          style: ReforgeTypography.chip.copyWith(
            color: isSelected ? Colors.white : ReforgeColors.graphite,
          ),
        ),
      ),
    );
  }
}

/// Individual idea card in the list.
class _IdeaCard extends StatelessWidget {
  final Idea idea;
  final VoidCallback onTap;

  const _IdeaCard({required this.idea, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTimeAgo(idea.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ReforgeColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ReforgeColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Tags + Status + Time
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  // Category tags
                  if (idea.tags.isNotEmpty) ...[
                    for (final tag in idea.tags.take(2))
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _TagBadge(tag: tag),
                      ),
                  ],
                  // Status badge
                  _StatusBadge(status: idea.status),
                  const Spacer(),
                  // Time
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 14,
                        color: ReforgeColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(timeAgo, style: ReforgeTypography.meta),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                idea.title,
                style: ReforgeTypography.cardTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Description snippet
            if (idea.description != null && idea.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Text(
                  idea.description!,
                  style: ReforgeTypography.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Hypothesis callout
            if (idea.hypothesis != null && idea.hypothesis!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ReforgeColors.quoteBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ReforgeColors.quoteBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hypothesis: ${idea.hypothesis!}',
                          style: ReforgeTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                            color: ReforgeColors.graphite,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Bottom: Tech tags + Revisions + Action
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  // Tech/code tags
                  if (idea.tags.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.code,
                          size: 14,
                          color: ReforgeColors.muted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          idea.tags.map((t) => t.name).take(3).join(' · '),
                          style: ReforgeTypography.meta,
                        ),
                      ],
                    ),
                  if (idea.revisionsCount > 1) ...[
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.refreshCw,
                          size: 14,
                          color: ReforgeColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${idea.revisionsCount} revisions',
                          style: ReforgeTypography.meta,
                        ),
                      ],
                    ),
                  ],
                  const Spacer(),
                  // CTA hint
                  if (idea.status == IdeaStatus.exploring ||
                      idea.status == IdeaStatus.active)
                    Text(
                      idea.status == IdeaStatus.exploring
                          ? 'Ready to Forge →'
                          : 'Deepen →',
                      style: ReforgeTypography.chip.copyWith(
                        color: ReforgeColors.forgeAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  // Overflow menu
                  const SizedBox(width: 8),
                  const Icon(
                    LucideIcons.ellipsis,
                    size: 18,
                    color: ReforgeColors.muted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return DateFormat('MMM d, y').format(date);
  }
}

/// Status badge pill.
class _StatusBadge extends StatelessWidget {
  final IdeaStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      IdeaStatus.active => (ReforgeColors.successBg, ReforgeColors.success),
      IdeaStatus.exploring => (ReforgeColors.warningBg, ReforgeColors.warning),
      IdeaStatus.building => (ReforgeColors.categoryBg, ReforgeColors.category),
      IdeaStatus.converted => (ReforgeColors.successBg, ReforgeColors.success),
      IdeaStatus.archived => (ReforgeColors.codeBg, ReforgeColors.muted),
      IdeaStatus.draft => (ReforgeColors.codeBg, ReforgeColors.muted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: ReforgeTypography.badge.copyWith(color: fg),
      ),
    );
  }
}

/// Category tag badge (purple tint).
class _TagBadge extends StatelessWidget {
  final Tag tag;
  const _TagBadge({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ReforgeColors.categoryBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tag.name,
        style: ReforgeTypography.badge.copyWith(color: ReforgeColors.category),
      ),
    );
  }
}

/// Empty state shown when no ideas exist.
class _EmptyVaultState extends StatelessWidget {
  const _EmptyVaultState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ReforgeColors.warningBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.lightbulb,
                size: 36,
                color: ReforgeColors.forgeAccent,
              ),
            ),
            const SizedBox(height: 20),
            Text('Your vault is empty', style: ReforgeTypography.sectionTitle),
            const SizedBox(height: 8),
            Text(
              'Capture your first spark.\nEvery great product starts with a rough idea.',
              textAlign: TextAlign.center,
              style: ReforgeTypography.body,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for quick idea capture (title-only fast capture).
class _QuickCaptureSheet extends ConsumerStatefulWidget {
  const _QuickCaptureSheet();

  @override
  ConsumerState<_QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends ConsumerState<_QuickCaptureSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _selectedTagIds = {};
  bool _isExpanded = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagsListProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ReforgeColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              const Icon(
                LucideIcons.zap,
                size: 20,
                color: ReforgeColors.forgeAccent,
              ),
              const SizedBox(width: 8),
              Text('Quick Capture', style: ReforgeTypography.sectionTitle),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Just a title is enough. Flesh it out later.',
            style: ReforgeTypography.body,
          ),
          const SizedBox(height: 16),

          // Title field
          TextField(
            controller: _titleController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: ReforgeTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: 'What\'s the spark?',
              hintStyle: ReforgeTypography.body.copyWith(
                color: ReforgeColors.subtle,
              ),
              filled: true,
              fillColor: ReforgeColors.elevatedSurface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          // Expanded fields
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style: ReforgeTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Brief description (optional)',
                hintStyle: ReforgeTypography.body.copyWith(
                  color: ReforgeColors.subtle,
                ),
                filled: true,
                fillColor: ReforgeColors.elevatedSurface,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Tags', style: ReforgeTypography.bodyMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _createTag,
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('New tag'),
                ),
              ],
            ),
            SizedBox(
              height: 42,
              child: tagsAsync.when(
                data: (tags) => tags.isEmpty
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'No tags yet',
                          style: ReforgeTypography.meta,
                        ),
                      )
                    : ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final tag in tags)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(tag.name),
                                selected: _selectedTagIds.contains(tag.id),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedTagIds.add(tag.id);
                                    } else {
                                      _selectedTagIds.remove(tag.id);
                                    }
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                loading: () => const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, _) => Text(
                  'Tags could not be loaded',
                  style: ReforgeTypography.meta.copyWith(
                    color: ReforgeColors.danger,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Expand toggle + Submit
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                icon: Icon(
                  _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 16,
                ),
                label: Text(_isExpanded ? 'Less' : 'Add details'),
                style: TextButton.styleFrom(
                  foregroundColor: ReforgeColors.muted,
                  textStyle: ReforgeTypography.chip,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _isSubmitting ? null : _submitIdea,
                style: FilledButton.styleFrom(
                  backgroundColor: ReforgeColors.forgeAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Capture Spark',
                        style: ReforgeTypography.buttonPrimary,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitIdea() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSubmitting = true);

    final idea = await ref
        .read(ideasActionProvider.notifier)
        .createIdea(
          title: title,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          tagIds: _selectedTagIds.toList(),
        );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (idea != null) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the idea. Please try again.'),
        ),
      );
    }
  }

  Future<void> _createTag() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Tag name'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || name == null || name.trim().isEmpty) return;

    final tag = await ref
        .read(ideasActionProvider.notifier)
        .createTag(name: name.trim());
    if (!mounted) return;
    if (tag == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create the tag. Please try again.'),
        ),
      );
      return;
    }
    setState(() => _selectedTagIds.add(tag.id));
  }
}
