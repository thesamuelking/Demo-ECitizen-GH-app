import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ghanaserve/widgets/app_back_button.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _callSupport() async {
    final uri = Uri(scheme: 'tel', path: '0800100900');
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the phone app.')),
      );
    }
  }

  void _submitComplaint() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _subjectController.clear();
    _detailsController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your complaint has been submitted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Contact Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('We are here to help', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 6),
          Text('Speak with our support team or send us a complaint.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primary.withOpacity(.12),
                child: Icon(Icons.phone_in_talk_outlined, color: scheme.primary),
              ),
              title: const Text('0800 100 900', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Free call · Monday to Friday, 8:00 AM to 5:00 PM'),
              trailing: FilledButton(onPressed: _callSupport, child: const Text('Call')),
            ),
          ),
          const SizedBox(height: 22),
          Text('Submit a complaint', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Subject is required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _detailsController,
                      minLines: 5,
                      maxLines: 7,
                      decoration: const InputDecoration(labelText: 'Tell us what happened'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please describe your complaint' : null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _submitComplaint, icon: const Icon(Icons.send_outlined, size: 18), label: const Text('Submit complaint'))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
