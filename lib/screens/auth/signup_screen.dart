import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ghanaserve/models/auth_models.dart';
import 'package:ghanaserve/providers/auth_provider.dart';
import 'package:ghanaserve/screens/auth/auth_validators.dart';
import 'package:ghanaserve/screens/auth/auth_widgets.dart';
import 'package:ghanaserve/theme/auth_theme.dart';
import 'package:ghanaserve/widgets/app_back_button.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ghanacardCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _termsAccepted = false;
  int _step = 0; // 0 = personal, 1 = credentials

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _ghanacardCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _step = 1);
  }

  Future<void> _submit() async {
    ref.read(authProvider.notifier).clearError();
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please accept the terms and conditions to continue.',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).signUp(
          SignUpRequest(
            fullName: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            password: _passwordCtrl.text,
            ghanacardNumber: _ghanacardCtrl.text.trim().toUpperCase(),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),

                  // Back button
                  _step == 1
                      ? MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => setState(() => _step = 0),
                            child: const AppBackButton(
                              fallbackRoute: '/login',
                              foregroundColor: Colors.white,
                              backgroundColor: AuthColors.card,
                            ),
                          ),
                        )
                      : const AppBackButton(
                          fallbackRoute: '/login',
                          foregroundColor: Colors.white,
                          backgroundColor: AuthColors.card,
                        ),
                  const SizedBox(height: 28),

                  // Step indicator
                  _StepIndicator(step: _step),
                  const SizedBox(height: 28),

                  // Headline
                  Text(
                    _step == 0
                        ? 'Create your\naccount 🇬🇭'
                        : 'Set your\ncredentials 🔐',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _step == 0
                        ? 'Access all Ghana government services in one place'
                        : 'Your password protects your identity and documents',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AuthColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error banner
                  if (error != null) ...[
                    AuthErrorBanner(message: error),
                    const SizedBox(height: 16),
                  ],

                  // Form
                  Form(
                    key: _formKey,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _step == 0
                          ? _PersonalStep(
                              key: const ValueKey('personal'),
                              nameCtrl: _nameCtrl,
                              emailCtrl: _emailCtrl,
                              phoneCtrl: _phoneCtrl,
                              ghanacardCtrl: _ghanacardCtrl,
                              onNext: _nextStep,
                            )
                          : _CredentialsStep(
                              key: const ValueKey('credentials'),
                              passwordCtrl: _passwordCtrl,
                              confirmCtrl: _confirmCtrl,
                              obscurePassword: _obscurePassword,
                              obscureConfirm: _obscureConfirm,
                              termsAccepted: _termsAccepted,
                              isLoading: isLoading,
                              onTogglePassword: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              onToggleConfirm: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              onTermsChanged: (v) =>
                                  setState(() => _termsAccepted = v ?? false),
                              onSubmit: _submit,
                            ),
                    ),
                  ),

                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?  ',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AuthColors.textMuted,
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            'Sign In',
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
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Step 0: Personal Info ─────────────────────────────────────────────────────

class _PersonalStep extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController ghanacardCtrl;
  final VoidCallback onNext;

  const _PersonalStep({
    super.key,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.ghanacardCtrl,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AuthTextField(
          controller: nameCtrl,
          label: 'Full Name',
          hint: 'As it appears on your Ghana Card',
          icon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
          validator: AuthValidators.fullName,
        ),
        const SizedBox(height: 14),
        AuthTextField(
          controller: emailCtrl,
          label: 'Email Address',
          hint: 'you@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: AuthValidators.email,
        ),
        const SizedBox(height: 14),
        AuthTextField(
          controller: phoneCtrl,
          label: 'Mobile Number',
          hint: '0XX XXX XXXX',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: AuthValidators.phone,
        ),
        const SizedBox(height: 14),
        AuthTextField(
          controller: ghanacardCtrl,
          label: 'Ghana Card Number (optional)',
          hint: 'GHA-000000000-0',
          icon: Icons.credit_card_rounded,
          textInputAction: TextInputAction.done,
          validator: AuthValidators.ghanacard,
        ),
        const SizedBox(height: 28),
        AuthPrimaryButton(
          label: 'Continue →',
          isLoading: false,
          onPressed: onNext,
        ),
      ],
    );
  }
}

// ── Step 1: Password ──────────────────────────────────────────────────────────

class _CredentialsStep extends StatelessWidget {
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool termsAccepted;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final void Function(bool?) onTermsChanged;
  final VoidCallback onSubmit;

  const _CredentialsStep({
    super.key,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.termsAccepted,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onTermsChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthTextField(
          controller: passwordCtrl,
          label: 'Password',
          hint: 'Min. 8 characters',
          icon: Icons.lock_outline_rounded,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.next,
          validator: AuthValidators.passwordSignUp,
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: AuthColors.textMuted,
            ),
            onPressed: onTogglePassword,
          ),
        ),
        const SizedBox(height: 14),
        AuthTextField(
          controller: confirmCtrl,
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          icon: Icons.lock_outline_rounded,
          obscureText: obscureConfirm,
          textInputAction: TextInputAction.done,
          validator: (v) =>
              AuthValidators.confirmPassword(v, passwordCtrl.text),
          suffixIcon: IconButton(
            icon: Icon(
              obscureConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: AuthColors.textMuted,
            ),
            onPressed: onToggleConfirm,
          ),
        ),
        const SizedBox(height: 10),
        // Password strength guide
        _PasswordGuide(password: passwordCtrl.text),
        const SizedBox(height: 20),

        // Terms checkbox
        GestureDetector(
          onTap: () => onTermsChanged(!termsAccepted),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: termsAccepted,
                onChanged: onTermsChanged,
                activeColor: AuthColors.accent,
                checkColor: Colors.white,
                side: BorderSide(color: AuthColors.cardBorder, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AuthColors.textMuted),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AuthColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AuthColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' of the Republic of Ghana'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        AuthPrimaryButton(
          label: 'Create Account',
          isLoading: isLoading,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}

class _PasswordGuide extends StatelessWidget {
  final String password;
  const _PasswordGuide({required this.password});

  @override
  Widget build(BuildContext context) {
    final checks = [
      (label: '8+ characters', met: password.length >= 8),
      (label: 'Uppercase letter', met: password.contains(RegExp(r'[A-Z]'))),
      (label: 'Number', met: password.contains(RegExp(r'[0-9]'))),
      (
        label: 'Special character',
        met: password.contains(RegExp(r'[!@#\$%^&*]'))
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: checks.map((c) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              c.met
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 13,
              color: c.met ? AuthColors.accent : AuthColors.textMuted,
            ),
            const SizedBox(width: 3),
            Text(
              c.label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: c.met ? AuthColors.accent : AuthColors.textMuted,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(2, (i) {
        final active = i == step;
        final done = i < step;
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: active ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    done || active ? AuthColors.accent : AuthColors.cardBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (i < 1) const SizedBox(width: 6),
          ],
        );
      }),
    );
  }
}
