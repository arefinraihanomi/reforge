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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reflection Vault',
                        style: ReforgeTypography.screenTitle,
                      ),
                      const Text(
                        'Cross-project lessons & engineering takeaways',
                        style: ReforgeTypography.meta,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                    onPressed: () => ref.invalidate(allLessonsProvider),
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
              'When you pause or abandon builds, complete a post-mortem to extract key insights and engineering guidelines for future projects.',
              style: ReforgeTypography.meta,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(shellTabIndexProvider.notifier).state = 3; // Switch to Graveyard tab
              },
              icon: const Icon(LucideIcons.ghost, size: 16),
              label: const Text('View Project Graveyard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ReforgeColors.deepSlate,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
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
