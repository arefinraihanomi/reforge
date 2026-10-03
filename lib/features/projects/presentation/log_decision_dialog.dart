import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import 'projects_notifier.dart';

class LogDecisionDialog extends ConsumerStatefulWidget {
  final String projectId;
  final String? initialEntryType;

  const LogDecisionDialog({
    super.key,
    required this.projectId,
    this.initialEntryType,
  });

  static Future<void> show(
    BuildContext context, {
    required String projectId,
    String? initialEntryType,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LogDecisionDialog(
        projectId: projectId,
        initialEntryType: initialEntryType,
      ),
    );
  }

  @override
  ConsumerState<LogDecisionDialog> createState() => _LogDecisionDialogState();
}

class _LogDecisionDialogState extends ConsumerState<LogDecisionDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _decisionController;
  late final TextEditingController _rationaleController;
  late String _entryType;
  String _category = 'Other';
  bool _isSubmitting = false;
  String? _errorMessage;

  static const List<String> _categories = [
    'Architecture',
    'Database',
    'UI/UX',
    'Scope',
    'DevOps',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _decisionController = TextEditingController();
    _rationaleController = TextEditingController();
    _entryType = widget.initialEntryType ?? 'decision';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _decisionController.dispose();
    _rationaleController.dispose();
    super.dispose();
  }

  Future<void> _submitDecision() async {
    final title = _titleController.text.trim();
    final decision = _decisionController.text.trim();

    if (title.isEmpty || decision.isEmpty) {
      setState(() => _errorMessage = 'Please provide both title and decision content.');
      return;
    }

    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(projectsActionProvider.notifier).logDecision(
            projectId: widget.projectId,
            title: title,
            decision: decision,
            rationale: _rationaleController.text.trim(),
            entryType: _entryType,
            category: _category,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged to Project Memory!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: ReforgeColors.warmSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
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
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ReforgeColors.deepSlate.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.bookmarkPlus,
                  color: ReforgeColors.deepSlate,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log Project Memory',
                      style: ReforgeTypography.screenTitle.copyWith(fontSize: 18),
                    ),
                    const Text(
                      'Record architectural choices, blockers, or notes in 2 taps',
                      style: ReforgeTypography.meta,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ReforgeColors.dangerBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ReforgeColors.dangerBorder),
              ),
              child: Text(
                _errorMessage!,
                style: ReforgeTypography.bodySmall.copyWith(
                  color: ReforgeColors.danger,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Entry Type Selector Pills
                  Text(
                    'Entry Type',
                    style: ReforgeTypography.cardTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTypePill('decision', 'Decision', LucideIcons.checkCircle2),
                      const SizedBox(width: 8),
                      _buildTypePill('blocker', 'Blocker', LucideIcons.alertTriangle),
                      const SizedBox(width: 8),
                      _buildTypePill('note', 'Note', LucideIcons.fileText),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Category Selector
                  Text(
                    'Category',
                    style: ReforgeTypography.cardTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _categories.map((cat) {
                      final isSelected = _category == cat;
                      return InkWell(
                        onTap: () => setState(() => _category = cat),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? ReforgeColors.categoryBg : ReforgeColors.cardSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? ReforgeColors.category : ReforgeColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? ReforgeColors.category : ReforgeColors.muted,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Title Field
                  Text(
                    'Summary Title',
                    style: ReforgeTypography.cardTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleController,
                    style: ReforgeTypography.body,
                    decoration: InputDecoration(
                      hintText: _entryType == 'blocker'
                          ? 'e.g. Supabase RLS recursion issue'
                          : 'e.g. Choose PostgreSQL over SQLite',
                      filled: true,
                      fillColor: ReforgeColors.cardSurface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: ReforgeColors.border),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Decision / Content Field
                  Text(
                    _entryType == 'blocker' ? 'Blocker Detail' : 'Decision / Insight',
                    style: ReforgeTypography.cardTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _decisionController,
                    maxLines: 3,
                    style: ReforgeTypography.body,
                    decoration: InputDecoration(
                      hintText: _entryType == 'blocker'
                          ? 'Describe what is blocking build progress...'
                          : 'What was decided and implemented...',
                      filled: true,
                      fillColor: ReforgeColors.cardSurface,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: ReforgeColors.border),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Rationale / Context (Optional)
                  Text(
                    'Rationale & Context (Optional)',
                    style: ReforgeTypography.cardTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _rationaleController,
                    maxLines: 2,
                    style: ReforgeTypography.body,
                    decoration: InputDecoration(
                      hintText: 'Why this decision was made...',
                      filled: true,
                      fillColor: ReforgeColors.cardSurface,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: ReforgeColors.border),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitDecision,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(LucideIcons.bookmarkCheck, size: 18),
            label: Text(_isSubmitting ? 'Saving Memory...' : 'Save to Project Memory'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ReforgeColors.deepSlate,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: ReforgeTypography.buttonPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypePill(String value, String label, IconData icon) {
    final isSelected = _entryType == value;
    Color color;
    if (value == 'blocker') {
      color = ReforgeColors.danger;
    } else if (value == 'decision') {
      color = ReforgeColors.success;
    } else {
      color = ReforgeColors.category;
    }

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _entryType = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : ReforgeColors.cardSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : ReforgeColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : ReforgeColors.subtle),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : ReforgeColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
