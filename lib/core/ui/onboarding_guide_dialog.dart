import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../../app/shell_screen.dart';

class OnboardingGuideStep {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final String corePrinciple;
  final int targetTab;

  const OnboardingGuideStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.corePrinciple,
    required this.targetTab,
  });
}

class ReforgeOnboardingDialog extends StatefulWidget {
  final WidgetRef ref;

  const ReforgeOnboardingDialog({super.key, required this.ref});

  static void show(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ReforgeOnboardingDialog(ref: ref),
    );
  }

  @override
  State<ReforgeOnboardingDialog> createState() => _ReforgeOnboardingDialogState();
}

class _ReforgeOnboardingDialogState extends State<ReforgeOnboardingDialog> {
  int _currentStep = 0;

  static const List<OnboardingGuideStep> _steps = [
    OnboardingGuideStep(
      title: 'Welcome to Reforge',
      description:
          'Reforge is your Calm Engineering Studio built for disciplined software architects. It helps you turn raw ideas into focused MVPs while eliminating feature creep.',
      icon: LucideIcons.flame,
      iconColor: ReforgeColors.forgeAccent,
      corePrinciple: 'Philosophy: Build small, measure fast, learn relentlessly.',
      targetTab: 0,
    ),
    OnboardingGuideStep(
      title: '1. Idea Vault (Sparks)',
      description:
          'Capture raw product ideas in under 2 minutes. Categorize with tags, measure Visual Idea Readiness Score (% Ready), and evolve concepts step-by-step.',
      icon: LucideIcons.lightbulb,
      iconColor: ReforgeColors.forgeAccent,
      corePrinciple: 'Rule: Don\'t start code until the Idea Spark is clear.',
      targetTab: 1,
    ),
    OnboardingGuideStep(
      title: '2. Project Workspace',
      description:
          'Convert validated ideas into Active Builds (1-Tap Forge ⚡). Set strict MVP scope boundaries, manage checklists, and log architectural decision memory.',
      icon: LucideIcons.hammer,
      iconColor: Color(0xFF3B82F6),
      corePrinciple: 'Rule: Strictly enforce MVP boundaries. Prevent feature creep.',
      targetTab: 2,
    ),
    OnboardingGuideStep(
      title: '3. Graveyard Vault',
      description:
          'Abandoning unpromising ideas is a superpower! Store dead/paused builds in the Graveyard to analyze failure postmortems and free up focus.',
      icon: LucideIcons.skull,
      iconColor: ReforgeColors.danger,
      corePrinciple: 'Rule: Fail fast, document root causes, celebrate abandoned debt.',
      targetTab: 3,
    ),
    OnboardingGuideStep(
      title: '4. Reflection Vault',
      description:
          'Transform postmortem lessons into reusable Architecture & Scope Rules. Apply past learnings directly into your next build lineage!',
      icon: LucideIcons.bookOpen,
      iconColor: Color(0xFF10B981),
      corePrinciple: 'Rule: Never repeat the same architectural mistake twice.',
      targetTab: 4,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final isLastStep = _currentStep == _steps.length - 1;

    return Dialog(
      backgroundColor: ReforgeColors.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Stepper Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: step.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(step.icon, color: step.iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STEP ${_currentStep + 1} OF ${_steps.length}',
                        style: ReforgeTypography.overline.copyWith(
                          color: step.iconColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.title,
                        style: ReforgeTypography.screenTitle.copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18, color: ReforgeColors.muted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: ReforgeColors.border, height: 1),
            const SizedBox(height: 16),

            // Description Body & Core Principle Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ReforgeColors.warmSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ReforgeColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.description,
                    style: ReforgeTypography.body.copyWith(
                      height: 1.5,
                      color: ReforgeColors.graphite,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: step.iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: step.iconColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.shieldCheck, size: 16, color: step.iconColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step.corePrinciple,
                            style: ReforgeTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: step.iconColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stepper Dots & Action Buttons
            Row(
              children: [
                // Step Indicator Dots
                Row(
                  children: List.generate(
                    _steps.length,
                    (index) => Container(
                      width: index == _currentStep ? 18 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: index == _currentStep
                            ? ReforgeColors.forgeAccent
                            : ReforgeColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: () {
                      setState(() => _currentStep--);
                      widget.ref
                          .read(shellTabIndexProvider.notifier)
                          .selectTab(_steps[_currentStep].targetTab);
                    },
                    child: const Text('Back'),
                  ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    if (isLastStep) {
                      Navigator.pop(context);
                    } else {
                      setState(() => _currentStep++);
                      widget.ref
                          .read(shellTabIndexProvider.notifier)
                          .selectTab(_steps[_currentStep].targetTab);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: ReforgeColors.deepSlate,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(
                    isLastStep ? LucideIcons.check : LucideIcons.arrowRight,
                    size: 16,
                  ),
                  label: Text(isLastStep ? 'Get Started' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
