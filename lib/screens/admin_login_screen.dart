import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ghanaserve/data/services_data.dart';
import 'package:ghanaserve/models/auth_models.dart';
import 'package:ghanaserve/providers/auth_provider.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _role;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_role == null || !_formKey.currentState!.validate()) return;
        final ok = await ref.read(authProvider.notifier).signInAsAdmin(
                    SignInRequest(
                        email: _email.text.trim(),
                        password: _password.text,
                        serviceDepartment: _role,
                    ),
                );
    if (!mounted) return;
    final user = ref.read(authProvider).valueOrNull?.user;
    if (ok && user?.isStaff == true) context.go('/admin');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider).valueOrNull;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Center(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                        key: _formKey,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('E-citizen GH',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF12372A))),
                              const SizedBox(height: 8),
                              Text('Government Staff Portal',
                                  style: GoogleFonts.inter(
                                      fontSize: 14, color: Colors.black54)),
                              const SizedBox(height: 28),
                              Text('Select your role',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                  initialValue: _role,
                                  isExpanded: true,
                                  hint:
                                      const Text('Choose a service department'),
                                  items: kServiceCategories
                                      .map((service) => DropdownMenuItem(
                                          value: service.title,
                                          child: Text(
                                              '${service.emoji}  ${service.title}')))
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _role = value),
                                  validator: (value) => value == null
                                      ? 'Select a service role'
                                      : null),
                              const SizedBox(height: 18),
                              TextFormField(
                                  controller: _email,
                                  decoration: const InputDecoration(
                                      labelText: 'Staff email',
                                      hintText: 'name@ecitizengh.com',
                                      prefixIcon: Icon(Icons.email_outlined)),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) =>
                                      value != null && value.contains('@')
                                          ? null
                                          : 'Enter a valid staff email'),
                              const SizedBox(height: 14),
                              TextFormField(
                                  controller: _password,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: Icon(Icons.lock_outline)),
                                  validator: (value) =>
                                      value != null && value.length >= 8
                                          ? null
                                          : 'Enter your password'),
                              if (auth?.error != null) ...[
                                const SizedBox(height: 14),
                                Text(auth!.error!,
                                    style: const TextStyle(
                                        color: Color(0xFFB42318)))
                              ],
                              const SizedBox(height: 24),
                              SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                      onPressed: auth?.isLoading == true
                                          ? null
                                          : _submit,
                                      icon: const Icon(Icons.login_rounded),
                                      label: const Text('Enter dashboard'))),
                              const SizedBox(height: 12),
                              Center(
                                  child: TextButton(
                                      onPressed: () => context.go('/login'),
                                      child: const Text(
                                          'Back to citizen sign in'))),
                            ])),
                  )),
            )),
      ),
    );
  }
}
