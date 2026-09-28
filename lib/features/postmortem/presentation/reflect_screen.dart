import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  static const _categories = [
    {'id': 'all', 'label': 'All Lessons'},
    {'id': 'architecture', 'label': 'Architecture'},
    {'id': 'scope', 'label': 'Scope'},
    {'id': 'technical', 'label': 'Technical'},
    {'id': 'process', 'label': 'Process'},
  ];

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

              const SizedBox(height: 16),

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
                          setState(() {
                            _selectedCategory = cat['id']!;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

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
                    final filteredLessons = _selectedCategory == 'all'
                        ? lessons
                        : lessons.where((l) => l.category.toLowerCase() == _selectedCategory).toList();

                    if (filteredLessons.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return ListView.separated(
                      itemCount: filteredLessons.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildLessonCard(filteredLessons[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ReforgeColors.forgeAccent,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text(
          'Record Lesson',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        onPressed: () => _showAddLessonDialog(context),
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

  Widget _buildLessonCard(ProjectLesson lesson) {
    final catColor = _getCategoryColor(lesson.category);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReforgeColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReforgeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              if (lesson.createdAt != null)
                Text(
                  DateFormat.yMMMd().format(lesson.createdAt!),
                  style: ReforgeTypography.meta.copyWith(fontSize: 11),
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
        ],
      ),
    );
  }
}
