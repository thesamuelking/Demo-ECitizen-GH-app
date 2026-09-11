import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ghanaserve/models/service_model.dart';
import 'package:ghanaserve/models/auth_models.dart';
import 'package:ghanaserve/data/services_data.dart';
import 'package:ghanaserve/providers/applications_provider.dart';
import 'package:ghanaserve/providers/auth_provider.dart';
import 'package:ghanaserve/providers/notification_provider.dart';
import 'package:ghanaserve/theme/app_theme.dart';
import 'package:ghanaserve/theme/auth_theme.dart';
import 'package:ghanaserve/widgets/status_badge.dart';
import 'package:ghanaserve/widgets/user_avatar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning,'
        : hour < 17
            ? 'Good afternoon,'
            : 'Good evening,';
    final user = ref.watch(authProvider).valueOrNull?.user;
    final applications =
        ref.watch(applicationsProvider).valueOrNull ?? const [];
    final notifications =
        ref.watch(appNotificationsProvider).valueOrNull ?? const [];
    if (user != null) {
      ref.read(applicationsProvider.notifier).loadForUser(user.id);
      ref.read(appNotificationsProvider.notifier).loadForUser(user.id);
    }
    final totalRequests = applications.length;
    final inProgress = applications.where((item) {
      switch (item.status) {
        case ApplicationStatus.pending:
        case ApplicationStatus.processing:
        case ApplicationStatus.approved:
          return true;
        case ApplicationStatus.draft:
        case ApplicationStatus.rejected:
        case ApplicationStatus.ready:
          return false;
      }
    }).length;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _ProfileDrawer(
        user: user,
        notifications: notifications,
        onSignOut: () async {
          await ref.read(authProvider.notifier).signOut();
          if (context.mounted) context.go('/login');
        },
      ),
      body: CustomScrollView(
        slivers: [
          // ── Hero header ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Independence_Arch.jpg'),
                  fit: BoxFit.cover,
                  colorFilter:
                      ColorFilter.mode(Color(0xB843208F), BlendMode.darken),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Builder(
                            builder: (context) => IconButton(
                              tooltip: 'Open menu',
                              onPressed: () =>
                                  Scaffold.of(context).openDrawer(),
                              icon: const Icon(Icons.menu_rounded,
                                  color: Colors.white),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  greeting,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.red[100],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  user?.fullName ?? '',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Account menu',
                            offset: const Offset(0, 52),
                            onSelected: (value) {
                              switch (value) {
                                case 'notifications':
                                  context.push('/notifications');
                                case 'edit':
                                  context.go('/profile');
                                case 'logout':
                                  _confirmSignOut(context, ref);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'notifications',
                                child: _AccountMenuItem(
                                  icon: Icons.notifications_none_rounded,
                                  label: 'Notifications',
                                  badge: notifications
                                      .where((item) => !item.isRead)
                                      .length,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: _AccountMenuItem(
                                  icon: Icons.edit_outlined,
                                  label: 'Edit details',
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'logout',
                                child: _AccountMenuItem(
                                  icon: Icons.logout_rounded,
                                  label: 'Sign out',
                                  destructive: true,
                                ),
                              ),
                            ],
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    UserAvatar(photo: user?.profilePhoto),
                                    if (notifications
                                        .any((item) => !item.isRead))
                                      Positioned(
                                        right: -2,
                                        top: -3,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: AppColors.ghRed,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AuthColors.background,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Ghana Card Preview
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'GHANA CARD',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.7),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: user?.hasGhanaCard == true
                                        ? Colors.green.withOpacity(0.3)
                                        : Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    user?.hasGhanaCard == true
                                        ? 'Active'
                                        : 'Not registered',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: user?.hasGhanaCard == true
                                          ? Colors.greenAccent[100]
                                          : Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              user?.hasGhanaCard == true
                                  ? user?.ghanacardNumber ?? ''
                                  : 'No Ghana Card linked',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 16,
                                color: Colors.white,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (user?.hasGhanaCard == true) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Expires: Dec 2031',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Flag stripe
                    const SizedBox(height: 20),
                    _GhanaStripe(),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Color(0xFF6D28D9),
                              size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text('Available balance',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                        const Spacer(),
                        Text('GH₵ 0.00',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _DashboardMetric(
                            icon: Icons.receipt_long_outlined,
                            value: '$totalRequests',
                            label: 'Total requests',
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DashboardMetric(
                            icon: Icons.pending_actions_outlined,
                            value: '$inProgress',
                            label: 'In progress',
                            color: const Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Quick Actions ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUICK ACTIONS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 520 ? 5 : 3;
                      return GridView.count(
                        crossAxisCount: columns,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.05,
                        children: [
                          _QuickAction(
                              emoji: '📋',
                              label: 'Apply',
                              asset: 'assets/images/apply1_bg.jpg',
                              onTap: () => context.go('/services')),
                          _QuickAction(
                              emoji: '🔍',
                              label: 'Track',
                              asset: 'assets/images/tracking_bg.webp',
                              onTap: () => context.go('/track')),
                          _QuickAction(
                              emoji: '📞',
                              label: 'Support',
                              asset: 'assets/images/support_bg.jpeg',
                              onTap: () => context.go('/profile')),
                          _QuickAction(
                              emoji: '📰',
                              label: 'News',
                              asset: 'assets/images/news_bg.jpeg',
                              onTap: () => _openGhanaNews(context)),
                          _QuickAction(
                              emoji: '✈️',
                              label: 'Tourism',
                              asset: 'assets/images/tourism_bg.jpg',
                              onTap: () => _openTourism(context)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Quick Services ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Text(
                'QUICK SERVICES',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final service = kServices
                      .where((service) => const {
                            'ghanacard',
                            'passport',
                            'drivers',
                            'nhis',
                            'gra-tax',
                            'ssnit',
                          }.contains(service.id))
                      .toList()[index];
                  return _QuickService(
                    service: service,
                    onTap: () =>
                        context.push('/services/detail', extra: service),
                  );
                },
                childCount: kServices
                    .where((service) => const {
                          'ghanacard',
                          'passport',
                          'drivers',
                          'nhis',
                          'gra-tax',
                          'ssnit',
                        }.contains(service.id))
                    .length,
              ),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 190,
                mainAxisExtent: 148,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
            ),
          ),

          // ── All Services ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'ALL SERVICES',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/services'),
                    child: const Text('View all'),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = kServiceCategories[index];
                return Padding(
                  padding: EdgeInsets.fromLTRB(20, index == 0 ? 12 : 0, 20, 8),
                  child: _CategoryTile(
                    category: category,
                    onTap: () => context.push('/services', extra: category),
                  ),
                );
              },
              childCount:
                  kServiceCategories.length > 3 ? 3 : kServiceCategories.length,
            ),
          ),

          // ── Recent Applications ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Applications',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/track'),
                    child: const Text('View all'),
                  ),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final app = applications[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: InkWell(
                    mouseCursor: app.status == ApplicationStatus.draft
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    borderRadius: BorderRadius.circular(14),
                    onTap: app.status == ApplicationStatus.draft
                        ? () => _openDraft(context, app)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.service,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                if (app.status != ApplicationStatus.draft) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    app.refNo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusBadge(status: app.status),
                              if (app.status == ApplicationStatus.draft) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  tooltip: 'Delete draft',
                                  icon:
                                      const Icon(Icons.delete_outline_rounded),
                                  iconSize: 20,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                  onPressed: () =>
                                      _deleteDraft(context, ref, app),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: applications.length > 2 ? 2 : applications.length,
            ),
          ),

          // ── Alert Banner ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCD116).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFCD116).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📣', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service Notice',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ghana Card registration centres open Saturday, 9am–2pm. Walk-ins welcome.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF92400E),
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
        ],
      ),
    );
  }

  Future<void> _openGhanaNews(BuildContext context) async {
    final uri = Uri.parse(
      'https://news.google.com/search?q=Ghana&hl=en-GH&gl=GH&ceid=GH%3Aen',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Ghana news right now.')),
      );
    }
  }

  Future<void> _openTourism(BuildContext context) async {
    final uri = Uri.parse(
      'https://www.google.com/search?q=Travel+and+Tour+in+Ghana',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to open Ghana tourism search right now.')),
      );
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (shouldSignOut == true) {
      await ref.read(authProvider.notifier).signOut();
      if (context.mounted) context.go('/login');
    }
  }

  Future<void> _deleteDraft(
    BuildContext context,
    WidgetRef ref,
    CitizenApplication application,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete draft?'),
        content: Text('Remove your ${application.service} draft?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete draft'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await ref
          .read(applicationsProvider.notifier)
          .deleteApplication(application.id);
    }
  }

  void _openDraft(BuildContext context, CitizenApplication application) {
    final service = kServices.firstWhere(
      (item) =>
          item.id == application.serviceId || item.title == application.service,
      orElse: () => kServices.first,
    );
    context.push(
      '/services/detail/apply',
      extra: {'service': service, 'draft': application},
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String emoji;
  final String label;
  final String asset;
  final VoidCallback onTap;

  const _QuickAction({
    required this.emoji,
    required this.label,
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2))
            ],
          ),
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox.expand(
                  child: Image.asset(
                    asset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF35515A),
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: Colors.white70),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 5),
                      Flexible(
                          child: Text(label,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _DashboardMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF26323A)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileDrawer extends StatelessWidget {
  final CitizenUser? user;
  final List<AppNotification> notifications;
  final Future<void> Function() onSignOut;

  const _ProfileDrawer({
    required this.user,
    required this.notifications,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 24),
              child: Row(
                children: [
                  UserAvatar(photo: user?.profilePhoto, size: 64, iconSize: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? 'Citizen',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close menu',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              badge: notifications.where((item) => !item.isRead).length,
              onTap: () {
                Navigator.pop(context);
                context.push('/notifications');
              },
            ),
            _DrawerItem(
              icon: Icons.lock_outline_rounded,
              label: 'Change Password',
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
            ),
            _DrawerItem(
              icon: Icons.history_rounded,
              label: 'History',
              onTap: () {
                Navigator.pop(context);
                context.push('/history');
              },
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
            _DrawerItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Funds',
              onTap: () {
                Navigator.pop(context);
                context.push('/funds');
              },
            ),
            _DrawerItem(
              icon: Icons.info_outline_rounded,
              label: 'About Us',
              onTap: () {
                Navigator.pop(context);
                context.push('/about');
              },
            ),
            _DrawerItem(
              icon: Icons.shield_outlined,
              label: 'Privacy Policy',
              onTap: () {
                Navigator.pop(context);
                context.push('/privacy');
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              destructive: true,
              onTap: () async {
                Navigator.pop(context);
                await onSignOut();
              },
            ),
            const SizedBox(height: 12),
            const _GhanaStripe(),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final bool destructive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? AppColors.ghRed : Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, size: 18, color: color),
      title: Text(label,
          style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      trailing: badge > 0
          ? CircleAvatar(
              radius: 10,
              backgroundColor: AppColors.ghRed,
              child: Text('$badge',
                  style: const TextStyle(fontSize: 10, color: Colors.white)),
            )
          : null,
      dense: true,
      onTap: onTap,
    );
  }
}

class _AccountMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final bool destructive;

  const _AccountMenuItem({
    required this.icon,
    required this.label,
    this.badge = 0,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 20, color: destructive ? AppColors.ghRed : AppColors.muted),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        if (badge > 0)
          CircleAvatar(
            radius: 10,
            backgroundColor: AppColors.ghRed,
            child: Text('$badge',
                style: const TextStyle(color: Colors.white, fontSize: 10)),
          ),
      ],
    );
  }
}

class _QuickService extends StatelessWidget {
  final GovernmentService service;
  final VoidCallback onTap;

  const _QuickService({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF3A2B45)
          : const Color(0xFFF3E8FF),
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      shadowColor: const Color(0x22000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: service.bgColor,
                  shape: BoxShape.circle,
                ),
                child:
                    Text(service.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const Spacer(),
              Text(
                service.title.replaceFirst(' Services', ''),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                service.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ServiceCategory category;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Text(category.emoji, style: const TextStyle(fontSize: 21)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
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
