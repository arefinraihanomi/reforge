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

    return Scaffold(
      backgroundColor: ReforgeColors.warmSurface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Brand Logo & Header
                  Center(
                    child: Image.asset(
                      'assets/brand/app_logo.png',
                      height: 48,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        'Reforge',
                        style: ReforgeTypography.screenTitle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'BUILD. LEARN. REBUILD.',
                      style: TextStyle(
                        fontFamily: ReforgeTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: ReforgeColors.forgeAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

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
                            style: ReforgeTypography.cardTitle.copyWith(fontSize: 18),
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
                          const SizedBox(height: 24),

                          // Submit Action CTA
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: authState.isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ReforgeColors.forgeAccent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
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
                          const SizedBox(height: 16),

                          // Divider
                          Row(
                            children: [
                              const Expanded(child: Divider(color: ReforgeColors.border)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'OR',
                                  style: ReforgeTypography.meta.copyWith(
                                    color: ReforgeColors.deepSlate,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: ReforgeColors.border)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Google Sign-In Button
                          SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: authState.isLoading
                                  ? null
                                  : () async {
                                      ref.read(authNotifierProvider.notifier).clearFeedback();
                                      await ref
                                          .read(authNotifierProvider.notifier)
                                          .signInWithGoogle();
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ReforgeColors.deepSlate,
                                side: const BorderSide(color: ReforgeColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const _GoogleLogo(),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Continue with Google',
                                      overflow: TextOverflow.ellipsis,
                                      style: ReforgeTypography.buttonPrimary.copyWith(
                                        color: ReforgeColors.deepSlate,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter widget rendering the official 4-color Google brand mark.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22;

    // Blue arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - paint.strokeWidth / 2),
      -0.5,
      2.1,
      false,
      paint,
    );

    // Green arc
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - paint.strokeWidth / 2),
      1.6,
      1.8,
      false,
      paint,
    );

    // Yellow arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - paint.strokeWidth / 2),
      3.4,
      1.0,
      false,
      paint,
    );

    // Red arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - paint.strokeWidth / 2),
      4.4,
      1.4,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

