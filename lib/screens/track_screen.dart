import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ghanaserve/models/service_model.dart';
import 'package:ghanaserve/data/services_data.dart';
import 'package:ghanaserve/providers/applications_provider.dart';
import 'package:ghanaserve/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghanaserve/theme/app_theme.dart';
import 'package:ghanaserve/widgets/status_badge.dart';
import 'package:ghanaserve/widgets/app_back_button.dart';

class TrackScreen extends ConsumerStatefulWidget {
  const TrackScreen({super.key});

  @override
  ConsumerState<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends ConsumerState<TrackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadApplications());
  }

  Future<void> _loadApplications() async {
    final user = ref.read(authProvider).valueOrNull?.user;
    if (user != null) {
      await ref
          .read(applicationsProvider.notifier)
          .loadForUser(user.id, forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final applications = ref.watch(applicationsProvider).valueOrNull ??
        const <CitizenApplication>[];
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF5425A8),
            foregroundColor: Colors.white,
            pinned: true,
            surfaceTintColor: const Color(0xFF5425A8),
            expandedHeight: 112,
            leading: const AppBackButton(),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(72, 0, 20, 12),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Track Applications',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Monitor your submissions',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFE9D5FF),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (applications.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                  child: Text('You have not submitted any applications yet.')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final app = applications[index];
                  return Padding(
                    padding:
                        EdgeInsets.fromLTRB(16, index == 0 ? 16 : 0, 16, 14),
                    child: _ApplicationCard(
                      application: app,
                      onTap: () => _openApplication(context, app),
                    ),
                  );
                },
                childCount: applications.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  void _openApplication(BuildContext context, CitizenApplication application) {
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

class _ApplicationCard extends StatelessWidget {
  final CitizenApplication application;
  final VoidCallback onTap;

  const _ApplicationCard({required this.application, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rejected = application.status == ApplicationStatus.rejected;
    const stages = ['Received', 'Processing', 'Approved', 'Ready', 'Rejected'];
    final completed = [
      application.status != ApplicationStatus.draft,
      application.status == ApplicationStatus.processing ||
        application.status == ApplicationStatus.approved ||
        application.status == ApplicationStatus.ready,
      application.status == ApplicationStatus.approved ||
        application.status == ApplicationStatus.ready,
      application.status == ApplicationStatus.ready,
      rejected,
    ];

    return InkWell(
      mouseCursor: application.status == ApplicationStatus.draft
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onTap: application.status == ApplicationStatus.draft ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.service,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          application.refNo,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (application.status != ApplicationStatus.draft)
                    StatusBadge(status: application.status),
                ],
              ),
            ),
            if (application.status != ApplicationStatus.draft) ...[
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              // Progress tracker
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    for (var i = 0; i < stages.length; i++) ...[
                      _StageIndicator(
                        label: stages[i],
                        done: completed[i],
                        rejected: rejected && i == stages.length - 1,
                      ),
                      if (i < stages.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.only(bottom: 20),
                            color: rejected && i == stages.length - 2
                                ? AppColors.ghRed
                              : completed[i]
                                ? AppColors.ghGreen
                                : AppColors.border,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
            if (application.status != ApplicationStatus.draft)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Submitted ${application.date}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StageIndicator extends StatelessWidget {
  final String label;
  final bool done;
  final bool rejected;

  const _StageIndicator(
      {required this.label, required this.done, this.rejected = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: rejected
                ? AppColors.ghRed
              : done
                ? AppColors.ghGreen
                : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
                color: rejected
                  ? AppColors.ghRed
                  : done
                    ? AppColors.ghGreen
                    : AppColors.border,
              width: 2,
            ),
          ),
            child: done
              ? Icon(rejected ? Icons.close_rounded : Icons.check_rounded,
                size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 48,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                color: rejected
                  ? AppColors.ghRed
                  : done
                    ? AppColors.ghGreen
                    : AppColors.mutedLight,
            ),
          ),
        ),
      ],
    );
  }
}
