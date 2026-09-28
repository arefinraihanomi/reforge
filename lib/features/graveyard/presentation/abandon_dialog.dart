import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../postmortem/presentation/postmortem_notifier.dart';
import '../../projects/models/project.dart';

class AbandonDialog extends ConsumerStatefulWidget {
  final Project project;

  const AbandonDialog({
    super.key,
    required this.project,
  });

  static Future<void> show(BuildContext context, Project project) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AbandonDialog(project: project),
    );
  }

  @override
  ConsumerState<AbandonDialog> createState() => _AbandonDialogState();
}

class _AbandonDialogState extends ConsumerState<AbandonDialog> {
  String _selectedReason = 'scope_creep';
  late final TextEditingController _noteController;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitAbandonment() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await ref
        .read(postmortemActionProvider.notifier)
        .abandonProject(
          projectId: widget.project.id,
          primaryReason: _selectedReason,
          abandonNote: _noteController.text.trim(),
        );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        context.go('/postmortem/${widget.project.id}');
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to record abandonment. Please try again.';
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
          // Handle
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
                  color: ReforgeColors.dangerBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.ghost,
                  color: ReforgeColors.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deliberate Abandonment',
                      style: ReforgeTypography.screenTitle.copyWith(fontSize: 18),
                    ),
                    Text(
                      'Pause or stop "${widget.project.title}" guilt-free',
                      style: ReforgeTypography.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  // Guilt-Free Manifesto Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ReforgeColors.cardSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ReforgeColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.sparkles, size: 20, color: ReforgeColors.forgeAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Stopping a project is not a failure; it is extracting engineering knowledge for V2.',
                            style: ReforgeTypography.bodySmall.copyWith(
                              color: ReforgeColors.graphite,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Primary Reason Radio Options
                  Text(
                    'Primary Reason for Stopping',
                    style: ReforgeTypography.sectionTitle.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 10),

                  RadioGroup<String>(
                    groupValue: _selectedReason,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedReason = val);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildReasonTile(
                          'scope_creep',
                          'Scope Creep',
                          'MVP boundary exploded beyond reasonable dev effort',
                          LucideIcons.target,
                        ),
                        _buildReasonTile(
                          'technical_blocker',
                          'Technical Blocker',
                          'Hit architectural roadblock or library limitation',
                          LucideIcons.alertTriangle,
                        ),
                        _buildReasonTile(
                          'shifted_interest',
                          'Shifted Focus / Interest',
                          'Learned what was needed; motivation moved elsewhere',
                          LucideIcons.compass,
                        ),
                        _buildReasonTile(
                          'time_constraint',
                          'Time Constraints',
                          'Life or work priorities require pausing work',
                          LucideIcons.clock,
                        ),
                        _buildReasonTile(
                          'other',
                          'Other Reason',
                          'Any other rationale for archiving',
                          LucideIcons.helpCircle,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Final Notes Field
                  Text(
                    'Exit Note (Optional)',
                    style: ReforgeTypography.cardTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    style: ReforgeTypography.body,
                    decoration: InputDecoration(
                      hintText: 'Brief note on current state before archiving...',
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

          // Action Button
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitAbandonment,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(LucideIcons.ghost, size: 18),
            label: Text(_isSubmitting ? 'Archiving...' : 'Move to Graveyard & Start Post-Mortem'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ReforgeColors.danger,
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

  Widget _buildReasonTile(
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _selectedReason == value;

    return InkWell(
      onTap: () => setState(() => _selectedReason = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? ReforgeColors.dangerBg : ReforgeColors.cardSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? ReforgeColors.dangerBorder : ReforgeColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? ReforgeColors.danger : ReforgeColors.subtle,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ReforgeTypography.cardTitle.copyWith(
                      fontSize: 14,
                      color: isSelected ? ReforgeColors.danger : ReforgeColors.graphite,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: ReforgeTypography.meta,
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              activeColor: ReforgeColors.danger,
            ),
          ],
        ),
      ),
    );
  }
}
