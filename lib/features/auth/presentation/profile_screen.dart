import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/supabase_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../ideas/presentation/ideas_notifier.dart';
import '../../postmortem/presentation/postmortem_notifier.dart';
import '../../projects/presentation/projects_notifier.dart';
import 'auth_notifier.dart';
import 'profile_notifier.dart';

/// Comprehensive Architect Profile screen styled strictly following
/// the Reforge "Industrial Precision & Calm Engineering Craft" design system.
///
/// Supports responsive Desktop/Web & Mobile modes.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _titleController;
  late final TextEditingController _bioController;
  late final TextEditingController _newTagController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _titleController = TextEditingController();
    _bioController = TextEditingController();
    _newTagController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    _newTagController.dispose();
    super.dispose();
  }

  void _populateControllers(UserProfileState profileState) {
    if (!_isEditing) {
      _displayNameController.text = profileState.profile.displayName;
      _titleController.text = profileState.title;
      _bioController.text = profileState.bio;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(profileNotifierProvider.notifier).updateProfile(
          displayName: _displayNameController.text,
          title: _titleController.text,
          bio: _bioController.text,
        );

    if (mounted && success) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: ReforgeColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    final activeProjectsAsync = ref.watch(activeProjectsProvider);
    final ideasStatsAsync = ref.watch(ideasStatsProvider);
    final ideasAsync = ref.watch(ideasListProvider);
    final graveyardAsync = ref.watch(abandonedProjectsProvider);
    final lessonsAsync = ref.watch(allLessonsProvider);

    final activeCount = activeProjectsAsync.value?.length ?? 0;
    final sparksCount = ideasStatsAsync.value?.totalSparks ?? ideasAsync.value?.length ?? 0;
    final graveyardCount = graveyardAsync.value?.length ?? 0;
    final lessonsCount = lessonsAsync.value?.length ?? 0;

    final email = currentUser?.email ?? 'arefin@reforge.dev';

    return Scaffold(
      backgroundColor: ReforgeColors.warmSurface,
      appBar: AppBar(
        title: const Text('Architect Profile', style: ReforgeTypography.screenTitle),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Profile',
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.invalidate(profileNotifierProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ReforgeColors.forgeAccent),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.alertTriangle, size: 36, color: ReforgeColors.danger),
                const SizedBox(height: 12),
                const Text('Failed to load profile', style: ReforgeTypography.cardTitle),
                const SizedBox(height: 8),
                Text(error.toString(), style: ReforgeTypography.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(profileNotifierProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (profileState) {
          _populateControllers(profileState);

          final profile = profileState.profile;
          final joinedDateStr = DateFormat.yMMMd().format(profile.createdAt);
          final initial = profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : 'A';

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 850;

              final metricCards = [
                _ProfileStatCard(
                  label: 'Active Builds',
                  count: activeCount,
                  icon: LucideIcons.hammer,
                  iconColor: const Color(0xFF3B82F6),
                ),
                _ProfileStatCard(
                  label: 'Sparks Captured',
                  count: sparksCount,
                  icon: LucideIcons.lightbulb,
                  iconColor: ReforgeColors.forgeAccent,
                ),
                _ProfileStatCard(
                  label: 'Graveyard Vault',
                  count: graveyardCount,
                  icon: LucideIcons.skull,
                  iconColor: ReforgeColors.danger,
                ),
                _ProfileStatCard(
                  label: 'Key Lessons',
                  count: lessonsCount,
                  icon: LucideIcons.bookOpen,
                  iconColor: const Color(0xFF10B981),
                ),
              ];

              final profileSettingsCard = Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ReforgeColors.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ReforgeColors.border),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.user, size: 18, color: ReforgeColors.forgeAccent),
                              SizedBox(width: 8),
                              Text('Profile Settings', style: ReforgeTypography.cardTitle),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isEditing = !_isEditing;
                                if (!_isEditing) {
                                  _populateControllers(profileState);
                                }
                              });
                            },
                            icon: Icon(_isEditing ? LucideIcons.x : LucideIcons.edit2, size: 14),
                            label: Text(_isEditing ? 'Cancel' : 'Edit'),
                            style: TextButton.styleFrom(
                              foregroundColor: ReforgeColors.forgeAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text('DISPLAY NAME', style: ReforgeTypography.overline),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _displayNameController,
                        enabled: _isEditing,
                        style: ReforgeTypography.bodyMedium,
                        decoration: const InputDecoration(
                          hintText: 'Enter display name',
                          prefixIcon: Icon(LucideIcons.user, size: 16),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Display name cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text('ENGINEERING ROLE / TITLE', style: ReforgeTypography.overline),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        enabled: _isEditing,
                        style: ReforgeTypography.bodyMedium,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Senior System Architect',
                          prefixIcon: Icon(LucideIcons.award, size: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('ACCOUNT EMAIL', style: ReforgeTypography.overline),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: email,
                        enabled: false,
                        style: ReforgeTypography.body.copyWith(color: ReforgeColors.muted),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(LucideIcons.lock, size: 16),
                          fillColor: ReforgeColors.warmSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('ENGINEERING PHILOSOPHY / BIO', style: ReforgeTypography.overline),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _bioController,
                        enabled: _isEditing,
                        maxLines: 3,
                        style: ReforgeTypography.body,
                        decoration: const InputDecoration(
                          hintText: 'Write a brief statement about your build methodology...',
                        ),
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: profileState.isLoading ? null : _saveProfile,
                            icon: profileState.isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(LucideIcons.check, size: 16),
                            label: const Text('Save Profile Changes'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );

              final techStackCard = Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ReforgeColors.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ReforgeColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.code, size: 18, color: ReforgeColors.forgeAccent),
                        SizedBox(width: 8),
                        Text('Primary Stack & Architecture', style: ReforgeTypography.cardTitle),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Technologies & tools used in your active build workspaces',
                      style: ReforgeTypography.caption,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profileState.techStack.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: ReforgeColors.categoryBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ReforgeColors.categoryBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tag,
                                style: const TextStyle(
                                  color: ReforgeColors.category,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: ReforgeTypography.fontFamily,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  ref.read(profileNotifierProvider.notifier).removeTechTag(tag);
                                },
                                child: const Icon(
                                  LucideIcons.x,
                                  size: 14,
                                  color: ReforgeColors.category,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newTagController,
                            style: ReforgeTypography.bodyMedium,
                            decoration: const InputDecoration(
                              hintText: 'Add technology (e.g. Docker, FFI, Go)',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                ref.read(profileNotifierProvider.notifier).addTechTag(val);
                                _newTagController.clear();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            final text = _newTagController.text;
                            if (text.trim().isNotEmpty) {
                              ref.read(profileNotifierProvider.notifier).addTechTag(text);
                              _newTagController.clear();
                            }
                          },
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: const Text('Add'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              final systemDiagnosticsCard = Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ReforgeColors.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ReforgeColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.cpu, size: 18, color: ReforgeColors.forgeAccent),
                        SizedBox(width: 8),
                        Text('System & Workshop Info', style: ReforgeTypography.cardTitle),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _SystemInfoRow(
                      label: 'Design System',
                      value: 'Reforge Industrial Light Theme',
                    ),
                    const Divider(height: 16),
                    const _SystemInfoRow(
                      label: 'Typography',
                      value: 'Inter Engine (7 Scale Ratios)',
                    ),
                    const Divider(height: 16),
                    _SystemInfoRow(
                      label: 'Backend Pipeline',
                      value: SupabaseBootstrap.isInitialized
                          ? 'Supabase Cloud (PostgreSQL + PKCE)'
                          : 'Local Workshop Mode',
                    ),
                    const Divider(height: 16),
                    const _SystemInfoRow(
                      label: 'App Version',
                      value: 'v1.0.0 (Build 2026.09.30)',
                    ),
                  ],
                ),
              );

              final signOutButton = SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sign Out', style: ReforgeTypography.cardTitle),
                        content: const Text(
                          'Are you sure you want to sign out of your Reforge architect workspace?',
                          style: ReforgeTypography.body,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ReforgeColors.danger,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      await ref.read(authNotifierProvider.notifier).signOut();
                    }
                  },
                  icon: const Icon(LucideIcons.logOut, size: 18, color: ReforgeColors.danger),
                  label: const Text(
                    'Sign Out of Reforge',
                    style: TextStyle(
                      color: ReforgeColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ReforgeColors.dangerBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              );

              return RefreshIndicator(
                color: ReforgeColors.forgeAccent,
                onRefresh: () async {
                  ref.invalidate(profileNotifierProvider);
                  ref.invalidate(activeProjectsProvider);
                  ref.invalidate(ideasStatsProvider);
                  ref.invalidate(abandonedProjectsProvider);
                  ref.invalidate(allLessonsProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- Hero Slate Header Card ---
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: ReforgeColors.deepSlate,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: ReforgeColors.deepSlateBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: ReforgeColors.forgeAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: CircleAvatar(
                                          radius: 28,
                                          backgroundColor: ReforgeColors.graphite,
                                          child: Text(
                                            initial,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: ReforgeTypography.fontFamily,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              profile.displayName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: ReforgeTypography.fontFamily,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              profileState.title,
                                              style: const TextStyle(
                                                color: ReforgeColors.deepSlateMuted,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: ReforgeTypography.fontFamily,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(LucideIcons.mail, size: 12, color: ReforgeColors.deepSlateMuted),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    email,
                                                    style: const TextStyle(
                                                      color: ReforgeColors.deepSlateMuted,
                                                      fontSize: 12,
                                                      fontFamily: ReforgeTypography.fontFamily,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),
                                  const Divider(color: ReforgeColors.deepSlateBorder),
                                  const SizedBox(height: 12),

                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: ReforgeColors.successBg,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: ReforgeColors.successBorder),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.circle, size: 8, color: ReforgeColors.success),
                                            const SizedBox(width: 6),
                                            Text(
                                              SupabaseBootstrap.isInitialized ? 'Workshop Active' : 'Local Workshop',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: ReforgeColors.success,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: ReforgeColors.forgeAccentBg,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: ReforgeColors.warningBorder),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(LucideIcons.shieldCheck, size: 12, color: ReforgeColors.forgeAccent),
                                            SizedBox(width: 6),
                                            Text(
                                              'VERIFIED BUILDER',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: ReforgeColors.forgeAccent,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E293B),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: ReforgeColors.deepSlateBorder),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(LucideIcons.calendar, size: 12, color: ReforgeColors.deepSlateMuted),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Joined $joinedDateStr',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: ReforgeColors.deepSlateMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // --- Engineering Metrics Summary Grid ---
                            const Text('Workshop Metrics', style: ReforgeTypography.sectionTitle),
                            const SizedBox(height: 12),

                            if (isDesktop)
                              Row(
                                children: metricCards
                                    .map((card) => Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 12),
                                            child: card,
                                          ),
                                        ))
                                    .toList(),
                              )
                            else ...[
                              Row(
                                children: [
                                  Expanded(child: metricCards[0]),
                                  const SizedBox(width: 12),
                                  Expanded(child: metricCards[1]),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: metricCards[2]),
                                  const SizedBox(width: 12),
                                  Expanded(child: metricCards[3]),
                                ],
                              ),
                            ],

                            const SizedBox(height: 28),

                            // --- Content Section (Desktop 2-Column vs Mobile Single Column) ---
                            if (isDesktop)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      children: [
                                        profileSettingsCard,
                                        const SizedBox(height: 20),
                                        techStackCard,
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        systemDiagnosticsCard,
                                        const SizedBox(height: 20),
                                        signOutButton,
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              profileSettingsCard,
                              const SizedBox(height: 20),
                              techStackCard,
                              const SizedBox(height: 20),
                              systemDiagnosticsCard,
                              const SizedBox(height: 20),
                              signOutButton,
                            ],

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color iconColor;

  const _ProfileStatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              Text(
                '$count',
                style: ReforgeTypography.statNumber.copyWith(fontSize: 22),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(label, style: ReforgeTypography.statLabel),
        ],
      ),
    );
  }
}

class _SystemInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _SystemInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: ReforgeTypography.bodySmall),
        Text(
          value,
          style: ReforgeTypography.bodyMedium.copyWith(
            fontSize: 13,
            color: ReforgeColors.graphite,
          ),
        ),
      ],
    );
  }
}
