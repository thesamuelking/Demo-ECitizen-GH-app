import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ghanaserve/models/auth_models.dart';
import 'package:ghanaserve/providers/auth_provider.dart';
import 'package:ghanaserve/screens/auth/auth_validators.dart';
import 'package:ghanaserve/screens/auth/auth_widgets.dart';
import 'package:ghanaserve/theme/auth_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _ghanacardCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _ghanaCardMode = false;
  bool _forgotPasswordMode = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _ghanacardCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(authProvider.notifier).clearError();
    if (!_formKey.currentState!.validate()) return;

    if (_forgotPasswordMode) {
      final success = await ref.read(authProvider.notifier).resetPassword(
            ResetPasswordRequest(
              email: _emailCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              newPassword: _passwordCtrl.text,
            ),
          );
      if (success && mounted) {
        setState(() {
          _forgotPasswordMode = false;
          _passwordCtrl.clear();
          _phoneCtrl.clear();
          _confirmPasswordCtrl.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully. Please sign in.')),
        );
      }
      return;
    }

    final success = _ghanaCardMode
        ? await ref.read(authProvider.notifier).signInWithGhanaCard(
              GhanaCardSignInRequest(
                ghanacardNumber: _ghanacardCtrl.text.trim().toUpperCase(),
              ),
            )
        : await ref.read(authProvider.notifier).signIn(
              SignInRequest(
                email: _emailCtrl.text.trim(),
                password: _passwordCtrl.text,
              ),
            );

    if (success && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider).valueOrNull;
    final isLoading = authState?.isLoading ?? false;
    final error = authState?.error;

    return Scaffold(
      backgroundColor: AuthColors.background,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Independence_Arch.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Color(0xB82D2B6E), BlendMode.darken),
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideIn,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    // Logo / brand mark
                    _BrandHeader(),
                    const SizedBox(height: 24),

                    // Headline
                    Text(
                                      _forgotPasswordMode ? 'Reset your\npassword' : 'Welcome\nback 👋',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _forgotPasswordMode
                          ? 'Verify your account to choose a new password'
                          : 'Sign in to access your government services',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AuthColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Error banner
                    if (error != null) ...[
                      AuthErrorBanner(message: error),
                      const SizedBox(height: 16),
                    ],

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_ghanaCardMode)
                            AuthTextField(
                              controller: _ghanacardCtrl,
                              label: 'Ghana Card Number',
                              hint: 'GHA-000000000-0',
                              icon: Icons.credit_card_rounded,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              validator: AuthValidators.ghanacard,
                            )
                          else ...[
                            AuthTextField(
                              controller: _emailCtrl,
                              label: 'Email Address',
                              hint: 'you@example.com',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: AuthValidators.email,
                            ),
                            const SizedBox(height: 16),
                            if (_forgotPasswordMode) ...[
                              AuthTextField(
                                controller: _phoneCtrl,
                                label: 'Phone Number',
                                hint: '024 123 4567',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                validator: AuthValidators.phone,
                              ),
                              const SizedBox(height: 16),
                            ],
                            AuthTextField(
                              controller: _passwordCtrl,
                              label: _forgotPasswordMode ? 'New Password' : 'Password',
                              hint: '********',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                                validator: _forgotPasswordMode
                                  ? AuthValidators.passwordSignUp
                                  : AuthValidators.passwordLogin,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: AuthColors.textMuted,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            if (_forgotPasswordMode) ...[
                              const SizedBox(height: 16),
                              AuthTextField(
                                controller: _confirmPasswordCtrl,
                                label: 'Confirm New Password',
                                hint: '********',
                                icon: Icons.lock_reset_outlined,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                validator: (value) => AuthValidators.confirmPassword(
                                  value,
                                  _passwordCtrl.text,
                                ),
                              ),
                            ],
                          ],
                          const SizedBox(height: 12),
                          if (!_forgotPasswordMode) Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => setState(() {
                                _forgotPasswordMode = true;
                                ref.read(authProvider.notifier).clearError();
                              }),
                              style: TextButton.styleFrom(
                                foregroundColor: AuthColors.accent,
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                'Forgot password?',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          if (_forgotPasswordMode)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => setState(() {
                                  _forgotPasswordMode = false;
                                  ref.read(authProvider.notifier).clearError();
                                }),
                                child: const Text('Back to sign in'),
                              ),
                            ),
                          const SizedBox(height: 28),

                          // Sign in button
                          AuthPrimaryButton(
                            label: _forgotPasswordMode ? 'Reset Password' : 'Sign In',
                            isLoading: isLoading,
                            onPressed: _submit,
                          ),

                          const SizedBox(height: 24),
                          _Divider(),
                          const SizedBox(height: 24),

                          // Ghana Card quick sign-in hint
                          if (!_forgotPasswordMode) _GhanaCardHint(
                            enabled: _ghanaCardMode,
                            onTap: () => setState(
                                () => _ghanaCardMode = !_ghanaCardMode),
                          ),
                          const SizedBox(height: 36),

                          // Sign up link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?  ",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AuthColors.textMuted,
                                ),
                              ),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => context.go('/signup'),
                                  child: Text(
                                    'Sign Up',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AuthColors.accent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          TextButton.icon(
                            onPressed: () => context.go('/admin-login'),
                            icon: const Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 18),
                            label: const Text('Government staff portal'),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AuthColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AuthColors.cardBorder),
          ),
          child:
              const Center(child: Text('🇬🇭', style: TextStyle(fontSize: 24))),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'E-citizen GH',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'Citizen Portal',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AuthColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AuthColors.cardBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: GoogleFonts.inter(fontSize: 12, color: AuthColors.textMuted),
          ),
        ),
        Expanded(child: Container(height: 1, color: AuthColors.cardBorder)),
      ],
    );
  }
}

class _GhanaCardHint extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _GhanaCardHint({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AuthColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AuthColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AuthColors.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                      child: Text('🪪', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign in with Ghana Card',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Use your NIA Ghana Card number',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AuthColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  enabled
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: AuthColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
