import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/shell_screen.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/lesson.dart';
import 'postmortem_notifier.dart';

class ReflectScreen extends ConsumerStatefulWidget {
  const ReflectScreen({super.key});

  @override
  ConsumerState<ReflectScreen> createState() => _ReflectScreenState();
}

class _ReflectScreenState extends ConsumerState<ReflectScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final Set<String> _pinnedLessonIds = {};
  final TextEditingController _searchController = TextEditingController();

  static const _categories = [
    {'id': 'all', 'label': 'All Lessons'},
    {'id': 'architecture', 'label': 'Architecture'},
    {'id': 'scope', 'label': 'Scope'},
    {'id': 'technical', 'label': 'Technical'},
    {'id': 'process', 'label': 'Process'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'architecture':
        return ReforgeColors.forgeAccent;
      case 'scope':
        return ReforgeColors.warning;
      case 'technical':
        return const Color(0xFF3B82F6);
      case 'process':
        return ReforgeColors.success;
      default:
        return ReforgeColors.subtle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(allLessonsProvider);

    return Scaffold(
      backgroundColor: ReforgeColors.warmSurface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reflection Vault',
                          style: ReforgeTypography.screenTitle,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Cross-project lessons & engineering takeaways',
                          style: ReforgeTypography.meta,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Record Lesson',
                        icon: const Icon(LucideIcons.plus, size: 20),
                        onPressed: () => _showAddLessonDialog(context),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        icon: const Icon(LucideIcons.refreshCw, size: 18),
                        onPressed: () => ref.invalidate(allLessonsProvider),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Search Input Bar
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search lessons, architecture rules, keywords...',
                  hintStyle: ReforgeTypography.bodySmall,
                  prefixIcon: const Icon(LucideIcons.search, size: 18, color: ReforgeColors.muted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
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
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ReforgeColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ReforgeColors.border),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(cat['label']!),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : ReforgeColors.graphite,
                        ),
                        selectedColor: ReforgeColors.deepSlate,
                        backgroundColor: ReforgeColors.cardSurface,
                        side: BorderSide(
                          color: isSelected ? ReforgeColors.deepSlate : ReforgeColors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedCategory = cat['id']!;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 14),

              // Content List
              Expanded(
                child: lessonsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: ReforgeColors.forgeAccent),
                  ),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 36, color: ReforgeColors.danger),
                        const SizedBox(height: 8),
                        const Text('Failed to load lessons', style: ReforgeTypography.cardTitle),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(allLessonsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (lessons) {
                    var filtered = _selectedCategory == 'all'
                        ? lessons
                        : lessons.where((l) => l.category.toLowerCase() == _selectedCategory).toList();

                    if (_searchQuery.isNotEmpty) {
                      filtered = filtered
                          .where((l) =>
                              l.lesson.toLowerCase().contains(_searchQuery) ||
                              l.category.toLowerCase().contains(_searchQuery))
                          .toList();
                    }

                    if (filtered.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    // Sort pinned lessons to the top
                    filtered.sort((a, b) {
                      final aPinned = _pinnedLessonIds.contains(a.id);
                      final bPinned = _pinnedLessonIds.contains(b.id);
                      if (aPinned && !bPinned) return -1;
                      if (!aPinned && bPinned) return 1;
                      return 0;
                    });

                    return Column(
                      children: [
                        // Stats Bar Summary Widget
                        _buildStatsHeader(lessons),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildLessonCard(filtered[index]);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
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
              child: const Icon(
                LucideIcons.bookOpen,
                size: 32,
                color: ReforgeColors.subtle,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Lessons Recorded Yet',
              style: ReforgeTypography.cardTitle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Capture key insights and engineering guidelines to prevent past pitfalls in future builds.',
              style: ReforgeTypography.meta,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showAddLessonDialog(context),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Record Lesson'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ReforgeColors.forgeAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(shellTabIndexProvider.notifier).selectTab(3); // Switch to Graveyard tab
                  },
                  icon: const Icon(LucideIcons.ghost, size: 16),
                  label: const Text('Graveyard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ReforgeColors.deepSlate,
                    side: const BorderSide(color: ReforgeColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddLessonDialog(BuildContext context) async {
    final lessonController = TextEditingController();
    String selectedCat = 'architecture';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: ReforgeColors.cardSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Record Engineering Lesson',
                        style: ReforgeTypography.cardTitle.copyWith(fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'What architectural pattern, scope lesson, or technical takeaway did you learn?',
                    style: ReforgeTypography.meta,
                  ),
                  const SizedBox(height: 16),
                  const Text('Category', style: ReforgeTypography.overline),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['architecture', 'scope', 'technical', 'process'].map((cat) {
                      final isSel = selectedCat == cat;
                      return ChoiceChip(
                        selected: isSel,
                        label: Text(cat.toUpperCase()),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : ReforgeColors.graphite,
                        ),
                        selectedColor: _getCategoryColor(cat),
                        backgroundColor: ReforgeColors.warmSurface,
                        side: BorderSide(
                          color: isSel ? _getCategoryColor(cat) : ReforgeColors.border,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setSheetState(() => selectedCat = cat);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: lessonController,
                    maxLines: 4,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'e.g., Decouple database layer with clean repository interfaces before writing UI.',
                      hintStyle: ReforgeTypography.bodySmall,
                      filled: true,
                      fillColor: ReforgeColors.warmSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: ReforgeColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ReforgeColors.forgeAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final text = lessonController.text.trim();
                        if (text.isEmpty) return;

                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.of(ctx).pop();
                        final created = await ref
                            .read(postmortemActionProvider.notifier)
                            .createLesson(
                              lesson: text,
                              category: selectedCat,
                            );

                        if (created != null) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Lesson added to Reflection Vault.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Save Lesson',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsHeader(List<ProjectLesson> lessons) {
    final total = lessons.length;
    final archCount = lessons.where((l) => l.category.toLowerCase() == 'architecture').length;
    final scopeCount = lessons.where((l) => l.category.toLowerCase() == 'scope').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ReforgeColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ReforgeColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.bookOpen, size: 16, color: ReforgeColors.forgeAccent),
              const SizedBox(width: 6),
              Text(
                '$total Lessons',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ReforgeColors.graphite),
              ),
            ],
          ),
          const SizedBox(
            height: 14,
            child: VerticalDivider(width: 1, color: ReforgeColors.border),
          ),
          Row(
            children: [
              const Icon(LucideIcons.layers, size: 16, color: ReforgeColors.warning),
              const SizedBox(width: 6),
              Text(
                '$archCount Arch Rules',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ReforgeColors.graphite),
              ),
            ],
          ),
          const SizedBox(
            height: 14,
            child: VerticalDivider(width: 1, color: ReforgeColors.border),
          ),
          Row(
            children: [
              const Icon(LucideIcons.target, size: 16, color: Color(0xFF3B82F6)),
              const SizedBox(width: 6),
              Text(
                '$scopeCount Scope Rules',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ReforgeColors.graphite),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(ProjectLesson lesson) {
    final catColor = _getCategoryColor(lesson.category);
    final isPinned = _pinnedLessonIds.contains(lesson.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReforgeColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPinned ? ReforgeColors.forgeAccent : ReforgeColors.border,
          width: isPinned ? 1.5 : 1.0,
        ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lesson.category.toUpperCase(),
                      style: ReforgeTypography.badge.copyWith(
                        color: catColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (lesson.projectId != null && lesson.projectId!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => context.push('/projects/${lesson.projectId}'),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: ReforgeColors.warmSurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: ReforgeColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(LucideIcons.link, size: 10, color: ReforgeColors.muted),
                            SizedBox(width: 4),
                            Text(
                              'Source Build',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: ReforgeColors.graphite),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  if (lesson.createdAt != null)
                    Text(
                      DateFormat.yMMMd().format(lesson.createdAt!),
                      style: ReforgeTypography.meta.copyWith(fontSize: 11),
                    ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        if (isPinned) {
                          _pinnedLessonIds.remove(lesson.id);
                        } else {
                          _pinnedLessonIds.add(lesson.id);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isPinned ? LucideIcons.pin : LucideIcons.pin,
                        size: 16,
                        color: isPinned ? ReforgeColors.forgeAccent : ReforgeColors.muted.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                LucideIcons.lightbulb,
                size: 18,
                color: ReforgeColors.forgeAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lesson.lesson,
                  style: ReforgeTypography.body.copyWith(
                    fontSize: 14,
                    height: 1.4,
                    color: ReforgeColors.deepSlate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: ReforgeColors.border),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(shellTabIndexProvider.notifier).selectTab(2);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Guideline ready to apply: "${lesson.lesson.substring(0, lesson.lesson.length > 30 ? 30 : lesson.lesson.length)}..."'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(LucideIcons.hammer, size: 14),
                label: const Text('Apply to Build', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  foregroundColor: ReforgeColors.forgeAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Copy Rule',
                    icon: const Icon(LucideIcons.copy, size: 15, color: ReforgeColors.muted),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: lesson.lesson));
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lesson copied to clipboard.'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Share Takeaway',
                    icon: const Icon(LucideIcons.share2, size: 15, color: ReforgeColors.muted),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Clipboard.setData(ClipboardData(text: 'Reforge Lesson [${lesson.category.toUpperCase()}]: ${lesson.lesson}'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Takeaway formatted & copied for sharing!'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
