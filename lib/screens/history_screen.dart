import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ghanaserve/providers/applications_provider.dart';
import 'package:ghanaserve/providers/auth_provider.dart';
import 'package:ghanaserve/theme/app_theme.dart';
import 'package:ghanaserve/widgets/app_back_button.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull?.user;
    final applications = ref.watch(applicationsProvider).valueOrNull ?? const [];
    if (user != null) ref.read(applicationsProvider.notifier).loadForUser(user.id);
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final recent = applications.where((item) => DateTime.tryParse(item.date)?.isAfter(weekAgo) ?? false).toList();
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: const Text('History')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text('Your activity', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 4),
          Text('A snapshot of the last seven days', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          _Section(title: 'Account activity', children: [
            _ActivityTile(icon: Icons.login_rounded, color: AppColors.ghGreen, title: 'Last login', detail: DateFormat('EEE, d MMM · h:mm a').format(now.subtract(const Duration(hours: 2)))),
            _ActivityTile(icon: Icons.logout_rounded, color: AppColors.muted, title: 'Last logout', detail: DateFormat('EEE, d MMM · h:mm a').format(now.subtract(const Duration(days: 1, hours: 3)))),
          ]),
          _Section(title: 'Applications and forms', children: recent.isEmpty
              ? [const _EmptyTile(text: 'No applications submitted in the last week.')]
              : recent.map((item) => _ActivityTile(icon: Icons.description_outlined, color: AppColors.nhisBlue, title: item.service, detail: 'Submitted ${item.date}')).toList()),
          _Section(title: 'Payments', children: const [
            _EmptyTile(text: 'No payment activity in the last week.'),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Card(child: Column(children: children)),
        ]),
      );
}

class _ActivityTile extends StatelessWidget {
  final IconData icon; final Color color; final String title; final String detail;
  const _ActivityTile({required this.icon, required this.color, required this.title, required this.detail});
  @override
  Widget build(BuildContext context) => ListTile(leading: CircleAvatar(backgroundColor: color.withOpacity(.12), child: Icon(icon, color: color, size: 19)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(detail));
}
class _EmptyTile extends StatelessWidget { final String text; const _EmptyTile({required this.text}); @override Widget build(BuildContext context) => ListTile(title: Text(text, style: Theme.of(context).textTheme.bodyMedium)); }
