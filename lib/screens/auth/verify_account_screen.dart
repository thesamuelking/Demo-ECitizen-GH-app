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

class VerifyAccountScreen extends ConsumerStatefulWidget {
  const VerifyAccountScreen({super.key});

  @override
  ConsumerState<VerifyAccountScreen> createState() =>
      _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends ConsumerState<VerifyAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  final _ghanacardCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: ref.read(authProvider).valueOrNull?.user?.fullName ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ghanacardCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final error = await ref.read(authProvider.notifier).verifyAccount(
          VerifyAccountRequest(
            fullName: _nameCtrl.text.trim(),
            ghanacardNumber: _ghanacardCtrl.text.trim().toUpperCase(),
          ),
        );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _isSubmitting = false;
        _error = error;
      });
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('verified successfully'),
        content: const Text('Your Ghana Card has been linked to your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (mounted) context.go('/profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBackButton(
                fallbackRoute: '/profile',
                foregroundColor: Colors.white,
                backgroundColor: AuthColors.card,
              ),
              const SizedBox(height: 44),
              Text(
                'Verify your\naccount',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the details used to register your Ghana Card.',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AuthColors.textMuted),
              ),
              const SizedBox(height: 28),
              if (_error != null) ...[
                AuthErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AuthTextField(
                      controller: _nameCtrl,
                      label: 'Full Name',
                      hint: 'Same name used during sign up',
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      validator: AuthValidators.fullName,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      controller: _ghanacardCtrl,
                      label: 'Ghana Card',
                      hint: 'GHA-000000000-0',
                      icon: Icons.credit_card_rounded,
                      textInputAction: TextInputAction.done,
                      validator: AuthValidators.ghanacardRequired,
                      onFieldSubmitted: (_) => _verify(),
                    ),
                    const SizedBox(height: 28),
                    AuthPrimaryButton(
                      label: 'Verify',
                      isLoading: _isSubmitting,
                      onPressed: _verify,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
