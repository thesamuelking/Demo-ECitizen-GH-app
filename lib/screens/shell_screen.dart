import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ghanaserve/theme/app_theme.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  int _locationIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/services')) return 1;
    if (location.startsWith('/track')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _locationIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 6)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  active: idx == 0,
                  onTap: () => context.go('/home'),
                ),
                _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Services',
                  active: idx == 1,
                  onTap: () => context.go('/services'),
                ),
                _NavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Payments',
                  active: false,
                  onTap: () => context.go('/funds'),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  active: idx == 3,
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 48,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFFFF7E6) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 23, color: active ? AppColors.ghRed : AppColors.mutedLight),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.ghRed : AppColors.mutedLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
