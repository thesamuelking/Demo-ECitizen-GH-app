import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ghanaserve/models/service_model.dart';
import 'package:ghanaserve/providers/auth_provider.dart';
import 'package:ghanaserve/services/admin_service.dart';
import 'package:ghanaserve/theme/app_theme.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final _service = AdminService();
  late Future<List<AdminApplication>> _applications;
  String _filter = 'all';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final department =
        ref.read(authProvider).valueOrNull?.user?.serviceDepartment;
    _applications = _service.fetchApplications(service: department);
  }

  void _refresh() => setState(_reload);

  String get _serviceDepartment =>
      ref.read(authProvider).valueOrNull?.user?.serviceDepartment ??
      'All services';

  Future<void> _changeStatus(
      AdminApplication application, ApplicationStatus status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.updateStatus(application.id, status);
      if (mounted) {
        _refresh();
        messenger.showSnackBar(SnackBar(
            content:
                Text('Application marked ${status.label.toLowerCase()}.')));
      }
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
            SnackBar(content: Text('Unable to update application: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
          backgroundColor: const Color(0xFF1684D8),
          foregroundColor: Colors.white,
          title: Text('Admin Dashboard',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800, color: Colors.white)),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Admin profile menu',
              offset: const Offset(0, 48),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: _GhanaFlagAvatar(),
              ),
              onSelected: (value) async {
                if (value == 'refresh') {
                  _refresh();
                  return;
                }
                final router = GoRouter.of(context);
                await ref.read(authProvider.notifier).signOut();
                if (mounted) router.go('/admin-login');
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'refresh',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.refresh_rounded),
                    title: Text('Refresh'),
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.logout_rounded),
                    title: Text('Logout'),
                  ),
                ),
              ],
            ),
          ]),
      body: FutureBuilder<List<AdminApplication>>(
          future: _applications,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child:
                      Text('Unable to load applications. ${snapshot.error}'));
            }
            final allApplications =
                (snapshot.data ?? const <AdminApplication>[])
                    .where((application) =>
                        application.status != ApplicationStatus.draft)
                    .toList();
            final counts = <String, int>{
              'all': allApplications.length,
              for (final status in [
                'pending',
                'processing',
                'approved',
                'rejected',
                'ready'
              ])
                status: allApplications
                    .where((item) => item.status.name == status)
                    .length,
            };
            final applications = allApplications
                .where(
                    (item) => _filter == 'all' || item.status.name == _filter)
                .where((item) =>
                    '${item.applicantName} ${item.refNo} ${item.service}'
                        .toLowerCase()
                        .contains(_search.toLowerCase()))
                .toList();
            return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                    padding:
                        EdgeInsets.all(constraints.maxWidth > 800 ? 32 : 16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dashboard control panel',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.account_balance_rounded,
                                  size: 17, color: AppColors.ghGreen),
                              const SizedBox(width: 6),
                              Text('Service: $_serviceDepartment',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ghGreen)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                              'Monitor applications and update citizen requests.'),
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, cardConstraints) {
                              const statuses = [
                                'all',
                                'pending',
                                'processing',
                                'approved',
                                'rejected',
                                'ready',
                              ];
                              Widget card(String status) => _StatusCard(
                                    label: status[0].toUpperCase() +
                                        status.substring(1),
                                    count: counts[status] ?? 0,
                                    selected: _filter == status,
                                    onTap: () =>
                                        setState(() => _filter = status),
                                  );

                              if (cardConstraints.maxWidth < 600) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      for (final status in statuses)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 12),
                                          child: SizedBox(
                                            width: 190,
                                            child: card(status),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }

                              return GridView.count(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 2.1,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  card('all'),
                                  card('pending'),
                                  card('ready'),
                                  card('processing'),
                                  card('approved'),
                                  card('rejected'),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          TextField(
                              decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.search),
                                  hintText:
                                      'Search applicant, reference, or service'),
                              onChanged: (value) =>
                                  setState(() => _search = value)),
                          const SizedBox(height: 18),
                          if (applications.isEmpty)
                            const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                    child: Text(
                                        'No applications match this view.'))),
                          ...applications.map((application) => _ApplicationTile(
                              application: application,
                              onStatusChanged: (status) =>
                                  _changeStatus(application, status))),
                        ])));
          }),
    );
  }
}

class _GhanaFlagAvatar extends StatelessWidget {
  const _GhanaFlagAvatar();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 34,
        height: 34,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                Expanded(child: Container(color: AppColors.ghRed)),
                Expanded(child: Container(color: AppColors.ghGold)),
                Expanded(child: Container(color: AppColors.ghGreen)),
              ],
            ),
            const Text('★',
                style: TextStyle(color: Colors.black, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _StatusCard({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (label.toLowerCase()) {
      'all' => const Color(0xFF7255E8),
      'pending' => const Color(0xFFF5B83D),
      'processing' => const Color(0xFF21B8C7),
      'approved' => const Color(0xFF2A8DDB),
      'rejected' => const Color(0xFFF24868),
      'ready' => const Color(0xFF16A36A),
      _ => const Color(0xFF1684D8),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 0,
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: selected
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('$count',
                  style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                label.toLowerCase() == 'all'
                    ? 'View all submitted applications'
                    : 'View the total number of ${label.toLowerCase()} applications',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  final AdminApplication application;
  final ValueChanged<ApplicationStatus> onStatusChanged;
  const _ApplicationTile(
      {required this.application, required this.onStatusChanged});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(application.service,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${application.applicantName}  •  ${application.refNo}'),
        trailing: Chip(
          label: Text(application.status.label),
          backgroundColor: application.status.bgColor,
          labelStyle: TextStyle(
              color: application.status.color, fontWeight: FontWeight.w700),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
                '${application.applicantEmail}\nSubmitted ${application.date}',
                style: const TextStyle(height: 1.6)),
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Documents:',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          if (application.documents.isNotEmpty) ...[
            ...application.documents.map(
              (document) => Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final url = Uri.tryParse(document['url'] as String? ?? '');
                    if (url != null) await launchUrl(url);
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(document['name'] as String? ?? 'View document'),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ] else
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('No documents uploaded.'),
            ),
          ...application.formData.entries.map((entry) => Align(
                alignment: Alignment.centerLeft,
                child: Text('${entry.key}: ${entry.value}'),
              )),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              if (application.status == ApplicationStatus.pending)
                OutlinedButton.icon(
                  onPressed: () =>
                      onStatusChanged(ApplicationStatus.processing),
                  icon: const Icon(Icons.hourglass_top_rounded),
                  label: const Text('Start process'),
                ),
              if (application.status == ApplicationStatus.pending ||
                  application.status == ApplicationStatus.processing)
                FilledButton.icon(
                  onPressed: () => onStatusChanged(ApplicationStatus.approved),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Approve'),
                ),
              if (application.status == ApplicationStatus.pending ||
                  application.status == ApplicationStatus.processing)
                TextButton.icon(
                  onPressed: () => onStatusChanged(ApplicationStatus.rejected),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Reject'),
                ),
              if (application.status == ApplicationStatus.approved)
                FilledButton.icon(
                  onPressed: () => onStatusChanged(ApplicationStatus.ready),
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Call for collection'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
