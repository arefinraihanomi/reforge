import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import 'auth_notifier.dart';

/// Screen facilitating user authentication for both Login and Signup modes.
class LoginScreen extends ConsumerStatefulWidget {
  final bool isSignUp;

  const LoginScreen({
    super.key,
    this.isSignUp = false,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _displayNameController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _displayNameController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Clear previous errors/successes
    ref.read(authNotifierProvider.notifier).clearFeedback();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _displayNameController.text.trim();

    if (widget.isSignUp) {
      await ref.read(authNotifierProvider.notifier).signUp(
            email: email,
            password: password,
            displayName: displayName.isNotEmpty ? displayName : null,
          );
    } else {
      await ref.read(authNotifierProvider.notifier).signIn(
            email: email,
            password: password,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    final formContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // App Brand Logo & Header
        Center(
          child: Image.asset(
            'assets/brand/app_logo.png',
            height: 48,
            errorBuilder: (context, error, stackTrace) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ReforgeColors.forgeAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.flame,
                    color: ReforgeColors.forgeAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Reforge',
                  style: ReforgeTypography.screenTitle,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'BUILD. LEARN. REBUILD.',
            style: TextStyle(
              fontFamily: ReforgeTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: ReforgeColors.forgeAccent,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Surface Card Container
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: ReforgeColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ReforgeColors.border),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.isSignUp ? 'Create your account' : 'Welcome back',
                  style: ReforgeTypography.cardTitle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isSignUp
                      ? 'Start capturing ideas, tracking decisions, and forging V2s.'
                      : 'Sign in to access your ideas and project memories.',
                  style: ReforgeTypography.body,
                ),
                const SizedBox(height: 24),

                // Error Message Feedback Banner
                if (authState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ReforgeColors.dangerBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ReforgeColors.dangerBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          size: 18,
                          color: ReforgeColors.danger,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            authState.errorMessage!,
                            style: ReforgeTypography.meta.copyWith(
                              color: ReforgeColors.danger,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Success Message Feedback Banner
                if (authState.successMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ReforgeColors.successBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ReforgeColors.successBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.checkCircle2,
                          size: 18,
                          color: ReforgeColors.success,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            authState.successMessage!,
                            style: ReforgeTypography.meta.copyWith(
                              color: ReforgeColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Optional Display Name Field for Signup
                if (widget.isSignUp) ...[
                  Text(
                    'Display Name',
                    style: ReforgeTypography.bodyMedium.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _displayNameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Arefin Raihan',
                      prefixIcon: Icon(LucideIcons.user, size: 18),
                    ),
                    validator: (value) {
                      if (widget.isSignUp &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Email Input Field
                Text(
                  'Email Address',
                  style: ReforgeTypography.bodyMedium.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'developer@example.com',
                    prefixIcon: Icon(LucideIcons.mail, size: 18),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Input Field
                Text(
                  'Password',
                  style: ReforgeTypography.bodyMedium.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(LucideIcons.lock, size: 18),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      icon: Icon(
                        _obscurePassword
                            ? LucideIcons.eye
                            : LucideIcons.eyeOff,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                // Live Password Strength Indicator (Signup Mode)
                if (widget.isSignUp && _passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: (_passwordController.text.length / 10).clamp(0.2, 1.0),
                            minHeight: 4,
                            backgroundColor: ReforgeColors.border,
                            color: _passwordController.text.length >= 8
                                ? ReforgeColors.success
                                : ReforgeColors.warning,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _passwordController.text.length >= 8 ? 'Strong' : 'Weak',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _passwordController.text.length >= 8
                              ? ReforgeColors.success
                              : ReforgeColors.warning,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Submit Action CTA
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ReforgeColors.forgeAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            widget.isSignUp
                                ? 'Create Account'
                                : 'Sign In',
                            style: ReforgeTypography.buttonPrimary.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: ReforgeColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: ReforgeTypography.meta,
                      ),
                    ),
                    const Expanded(child: Divider(color: ReforgeColors.border)),
                  ],
                ),
                const SizedBox(height: 12),

                // Google Sign-In Button
                SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: authState.isLoading
                        ? null
                        : () async {
                            await ref
                                .read(authNotifierProvider.notifier)
                                .signInWithGoogle();
                          },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: ReforgeColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(LucideIcons.globe, size: 18),
                    label: const Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Fast Demo Mode Sign-In Button
                if (!widget.isSignUp)
                  TextButton.icon(
                    onPressed: authState.isLoading
                        ? null
                        : () {
                            _emailController.text = 'demo@reforge.dev';
                            _passwordController.text = 'reforge123';
                            _submit();
                          },
                    icon: const Icon(LucideIcons.sparkles, size: 14, color: ReforgeColors.forgeAccent),
                    label: const Text(
                      'Fast Demo Mode Sign-In',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ReforgeColors.forgeAccent),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Segmented Switch Link
        Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                widget.isSignUp
                    ? 'Already have an account?'
                    : "Don't have an account?",
                style: ReforgeTypography.body,
              ),
              TextButton(
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).clearFeedback();
                  if (widget.isSignUp) {
                    context.go('/login');
                  } else {
                    context.go('/signup');
                  }
                },
                child: Text(
                  widget.isSignUp ? 'Sign In' : 'Sign Up',
                  style: ReforgeTypography.buttonSecondary.copyWith(
                    color: ReforgeColors.forgeAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: ReforgeColors.warmSurface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: isDesktop
                ? Container(
                    constraints: const BoxConstraints(maxWidth: 960),
                    decoration: BoxDecoration(
                      color: ReforgeColors.cardSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: ReforgeColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Left Hero Branding Panel (Desktop)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(48),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ReforgeColors.deepSlate,
                                  Color(0xFF1E293B),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: ReforgeColors.forgeAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: ReforgeColors.forgeAccent.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        LucideIcons.flame,
                                        color: ReforgeColors.forgeAccent,
                                        size: 14,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'CALM ENGINEERING STUDIO',
                                        style: TextStyle(
                                          color: ReforgeColors.forgeAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 28),
                                const Text(
                                  'Transform Stalled Projects Into Engineering Lessons.',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Reforge treats an idea, its execution journey, reasons it was paused, and its resurrection (V2) as a continuous engineering lifecycle.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ReforgeColors.subtle,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 36),
                                _HeroFeatureBadge(
                                  icon: LucideIcons.sparkles,
                                  title: 'Idea Vault & Readiness Score',
                                  subtitle: 'Capture sparks & score MVP feasibility',
                                ),
                                const SizedBox(height: 14),
                                _HeroFeatureBadge(
                                  icon: LucideIcons.fileCheck2,
                                  title: 'Structured Post-Mortems',
                                  subtitle: 'Document root causes & preserve takeaways',
                                ),
                                const SizedBox(height: 14),
                                _HeroFeatureBadge(
                                  icon: LucideIcons.hammer,
                                  title: 'V2 Resurrection Engine',
                                  subtitle: 'Build tighter iterations backed by lessons',
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Right Form Panel
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: formContent,
                          ),
                        ),
                      ],
                    ),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: formContent,
                  ),
          ),
        ),
      ),
    );
  }
}

class _HeroFeatureBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HeroFeatureBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, size: 18, color: ReforgeColors.forgeAccent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: ReforgeColors.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

