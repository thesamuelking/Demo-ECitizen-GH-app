import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ghanaserve/providers/auth_provider.dart';
import 'package:ghanaserve/models/auth_models.dart';
import 'package:ghanaserve/theme/app_theme.dart';
import 'package:ghanaserve/theme/auth_theme.dart';
import 'package:ghanaserve/widgets/user_avatar.dart';
import 'package:ghanaserve/widgets/app_back_button.dart';
import 'package:ghanaserve/screens/auth/auth_validators.dart';
import 'package:ghanaserve/providers/notification_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull?.user;
    if (user != null) {
      ref.read(notificationPreferencesProvider.notifier).loadForUser(user.id);
    }
    final menuItems = [
      _MenuItem(
          emoji: '👤',
          label: 'Personal Information',
          sub: 'Update your details'),
      _MenuItem(
          emoji: '🔔', label: 'Notifications', sub: 'SMS and email alerts'),
      _MenuItem(
          emoji: '🔒', label: 'Security & PIN', sub: 'Change password or PIN'),
      _MenuItem(emoji: '🌐', label: 'Language', sub: 'English (Ghana)'),
      _MenuItem(
          emoji: '📞',
          label: 'Contact Support',
          sub: '0800 100 900 · Free call'),
      _MenuItem(emoji: 'ℹ️', label: 'About E-citizen GH', sub: 'Version 2.1.0'),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Profile hero
          SliverToBoxAdapter(
            child: Container(
              color: AuthColors.background,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: AppBackButton(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.ghGreen,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 2,
                              ),
                            ),
                            child: UserAvatar(
                              photo: user?.profilePhoto,
                              size: 80,
                              iconSize: 40,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?.fullName ?? 'Citizen',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.green[100],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _Chip(label: '🇬🇭  Ghanaian Citizen'),
                              const SizedBox(width: 8),
                              user?.isVerified == true
                                  ? _Chip(label: '✓  Verified', gold: true)
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _Chip(label: 'Not verified'),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () =>
                                              context.push('/verify-account'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: AppColors.ghRed,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 5),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Text(
                                            'Verify account',
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const _GhanaStripe(),
                  ],
                ),
              ),
            ),
          ),

          // Menu items
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = menuItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        mouseCursor: SystemMouseCursors.click,
                        onTap: index == 0
                            ? () => showDialog<void>(
                                  context: context,
                                  builder: (_) =>
                                      _EditProfileDialog(user: user!),
                                )
                            : index == 2
                                ? () => showDialog<void>(
                                      context: context,
                                      builder: (_) =>
                                          const _ChangePasswordDialog(),
                                    )
                                : index == 1
                                    ? () => showModalBottomSheet<void>(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) =>
                                              const _NotificationsSheet(),
                                        )
                                    : index == 3
                                        ? () => _showLanguageDialog(context)
                                        : index == 4
                                            ? () => context.push('/support')
                                            : index == 5
                                                ? () => context.push('/about')
                                                : () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 32,
                                child: Text(
                                  item.emoji,
                                  style: const TextStyle(fontSize: 20),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.label,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                    Text(
                                      item.sub,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.border,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: menuItems.length,
              ),
            ),
          ),

          // Sign out
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              child: Align(
                alignment: Alignment.center,
                child: OutlinedButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ghRed,
                    side: const BorderSide(color: Color(0xFFFECACA), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 10),
                    minimumSize: const Size(130, 42),
                  ),
                  child: Text(
                    'Sign Out',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showLanguageDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Language'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
            title: const Text('British English'),
            subtitle: const Text('Current language'),
            trailing: Icon(Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary),
            onTap: () => Navigator.of(dialogContext).pop(),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            enabled: false,
            leading: Icon(Icons.language_outlined),
            title: Text('Other'),
            subtitle: Text('Unavailable', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

class _MenuItem {
  final String emoji;
  final String label;
  final String sub;
  const _MenuItem(
      {required this.emoji, required this.label, required this.sub});
}

class _Chip extends StatelessWidget {
  final String label;
  final bool gold;
  const _Chip({required this.label, this.gold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: gold
            ? const Color(0xFFFCD116).withOpacity(0.25)
            : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gold
              ? const Color(0xFFFCD116).withOpacity(0.5)
              : Colors.white.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: gold ? const Color(0xFFFEF08A) : Colors.white,
        ),
      ),
    );
  }
}

class _GhanaStripe extends StatelessWidget {
  const _GhanaStripe();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 3, color: AppColors.ghRed)),
        Expanded(child: Container(height: 3, color: AppColors.ghGold)),
        Expanded(child: Container(height: 3, color: AppColors.ghGreen)),
      ],
    );
  }
}

class _EditProfileDialog extends ConsumerStatefulWidget {
  final CitizenUser user;

  const _EditProfileDialog({required this.user});

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await ref.read(authProvider.notifier).changePassword(
          currentPassword: _currentCtrl.text,
          newPassword: _newCtrl.text,
        );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Security and PIN'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              TextFormField(
                controller: _currentCtrl,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Current password',
                  suffixIcon: IconButton(
                    tooltip:
                        _obscureCurrent ? 'Show password' : 'Hide password',
                    icon: Icon(_obscureCurrent
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: AuthValidators.passwordLogin,
              ),
              TextFormField(
                controller: _newCtrl,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'New password',
                  suffixIcon: IconButton(
                    tooltip: _obscureNew ? 'Show password' : 'Hide password',
                    icon: Icon(_obscureNew
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: AuthValidators.passwordSignUp,
              ),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
                  suffixIcon: IconButton(
                    tooltip:
                        _obscureConfirm ? 'Show password' : 'Hide password',
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (value) =>
                    AuthValidators.confirmPassword(value, _newCtrl.text),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Update password'),
        ),
      ],
    );
  }
}

class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences =
        ref.watch(notificationPreferencesProvider).valueOrNull ??
            const NotificationPreferences();
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Notifications',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ghBlack,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose how E-citizen GH keeps you updated.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            _NotificationToggle(
              icon: Icons.sms_outlined,
              title: 'SMS alerts',
              subtitle: 'Application updates and reminders',
              value: preferences.sms,
              onChanged: (value) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .setSms(value),
            ),
            const SizedBox(height: 10),
            _NotificationToggle(
              icon: Icons.mail_outline_rounded,
              title: 'Email alerts',
              subtitle: 'Receipts, status changes, and notices',
              value: preferences.email,
              onChanged: (value) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .setEmail(value),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value ? const Color(0xFFBBF7D0) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: value ? AppColors.ghGreen : AppColors.border,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: value ? Colors.white : AppColors.muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.ghGreen,
          ),
        ],
      ),
    );
  }
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  String? _photo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.fullName);
    _emailCtrl = TextEditingController(text: widget.user.email);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _photo = widget.user.profilePhoto;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes != null) {
      final extension = (file!.extension ?? 'png').toLowerCase();
      _photo = 'data:image/$extension;base64,${base64Encode(file.bytes!)}';
      setState(() {});
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final success = await ref.read(authProvider.notifier).updateProfile(
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          profilePhoto: _photo,
        );
    if (!mounted) return;
    if (success) Navigator.of(context).pop();
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update your details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(photo: _photo, size: 72, iconSize: 34),
            TextButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Change profile photo'),
            ),
            TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full name')),
            TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email address')),
            TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Mobile number')),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save changes'),
        ),
      ],
    );
  }
}
