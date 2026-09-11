import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ghanaserve/models/service_model.dart';
import 'package:ghanaserve/providers/applications_provider.dart';
import 'package:ghanaserve/providers/auth_provider.dart';
import 'package:ghanaserve/providers/notification_provider.dart';
import 'package:ghanaserve/theme/app_theme.dart';
import 'package:ghanaserve/widgets/app_back_button.dart';
import 'package:intl/intl.dart';

class ApplyScreen extends ConsumerStatefulWidget {
  final GovernmentService service;
  final CitizenApplication? draft;

  const ApplyScreen({super.key, required this.service, this.draft});

  @override
  ConsumerState<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends ConsumerState<ApplyScreen> {
  int _step = 0;
  bool _submitted = false;
  bool _loading = false;
  String _refNo = '';
  late final String _applicationId;
  final Map<String, String> _documents = {};

  final _formKey = GlobalKey<FormState>();

  // Step 0 controllers
  late final TextEditingController _nameCtrl;
  final _dobCtrl = TextEditingController();
  late final TextEditingController _ghanacardCtrl;
  String? _gender;

  // Step 1 controllers
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  String? _region;
  final _districtCtrl = TextEditingController();

  final List<String> _regions = [
    'Greater Accra',
    'Ashanti',
    'Western',
    'Eastern',
    'Central',
    'Volta',
    'Northern',
    'Upper East',
    'Upper West',
    'Bono',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).valueOrNull?.user;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _ghanacardCtrl = TextEditingController(text: user?.ghanacardNumber ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _applicationId =
        widget.draft?.id ?? 'app_${DateTime.now().microsecondsSinceEpoch}';
    final draftData = widget.draft?.formData ?? const <String, String>{};
    _step = int.tryParse(draftData['step'] ?? '') ?? 0;
    _dobCtrl.text = draftData['dob'] ?? '';
    _gender = _nonEmpty(draftData['gender']);
    _region = _nonEmpty(draftData['region']);
    _districtCtrl.text = draftData['district'] ?? '';
    _documents.addAll(widget.draft?.documents ?? const {});
    if (user != null) {
      ref.read(applicationsProvider.notifier).loadForUser(
        user.id,
        forceRefresh: true,
          ).then((_) {
        if (mounted && widget.draft == null) _saveDraft();
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _ghanacardCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  void _next() async {
    if (!_formKey.currentState!.validate()) return;
    if (_step < 3) {
      if (_step == 2 && !_allDocumentsUploaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please upload every required document before continuing.')),
        );
        return;
      }
      setState(() => _step++);
      await _saveDraft();
    } else {
      setState(() => _loading = true);
      await Future.delayed(const Duration(milliseconds: 1200));
      final prefix = widget.service.id.substring(0, 3).toUpperCase();
      final num =
          (100000 + DateTime.now().millisecond * 1000 % 900000).toString();
      setState(() {
        _loading = false;
        _submitted = true;
        _refNo = '$prefix-2026-$num';
      });
      final user = ref.read(authProvider).valueOrNull?.user;
      if (user != null) {
        await ref.read(applicationsProvider.notifier).upsertApplication(
              CitizenApplication(
                id: _applicationId,
                service: widget.service.title,
                status: ApplicationStatus.pending,
                date:
                    '${DateTime.now().day} ${_month(DateTime.now().month)} ${DateTime.now().year}',
                refNo: _refNo,
                serviceId: widget.service.id,
                serviceDepartment: widget.service.category,
                formData: _formData,
                documents: _documents,
              ),
            );
        await ref.read(appNotificationsProvider.notifier).addNotification(
              userId: user.id,
              id: 'application-submitted-$_applicationId',
              title: 'Application submitted',
              message:
                  'Your ${widget.service.title} application was submitted successfully.',
            );
      }
    }
  }

  String _month(int month) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][month - 1];

  String? _nonEmpty(String? value) =>
      value == null || value.trim().isEmpty ? null : value;

  List<String> get _requiredDocuments => widget.service.documents
      .where((document) => !document.toLowerCase().startsWith('previous '))
      .where((document) => !document.toLowerCase().contains('if applicable'))
      .where((document) => !document.toLowerCase().contains('if available'))
      .where((document) => !document.toLowerCase().contains('optional'))
      .toList();
    List<String> get _documentFields => widget.service.documents
      .where((document) => !document.toLowerCase().startsWith('previous '))
      .toList();
  bool get _allDocumentsUploaded =>
      _requiredDocuments.every((document) => _documents[document] != null);
  Map<String, String> get _formData => {
        'step': _step.toString(),
        'dob': _dobCtrl.text,
        'gender': _gender ?? '',
        'region': _region ?? '',
        'district': _districtCtrl.text,
      };

  Future<void> _saveDraft() async {
    final user = ref.read(authProvider).valueOrNull?.user;
    if (user == null || _submitted) return;
    await ref.read(applicationsProvider.notifier).upsertApplication(
          CitizenApplication(
            id: _applicationId,
            service: widget.service.title,
            status: ApplicationStatus.draft,
            date:
                '${DateTime.now().day} ${_month(DateTime.now().month)} ${DateTime.now().year}',
            refNo: 'Draft',
            serviceId: widget.service.id,
            serviceDepartment: widget.service.category,
            formData: _formData,
            documents: _documents,
          ),
        );
          await ref.read(appNotificationsProvider.notifier).addNotification(
            userId: user.id,
            id: 'draft-$_applicationId',
            title: 'Application draft saved',
            message: 'Your ${widget.service.title} draft is ready to continue.',
          );
  }

  Future<void> _uploadDocument(String document) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return;
    await _saveDraft();
    try {
      await ref.read(applicationsProvider.notifier).uploadDocument(
            applicationId: _applicationId,
            file: file,
          );
      setState(() => _documents[document] = file.name);
      await _saveDraft();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document upload failed: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;

    if (_submitted) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 12,
                left: 16,
                child: AppBackButton(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_rounded,
                            color: Color(0xFF059669),
                            size: 44,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Application Submitted!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your ${svc.title} application has been received. You will receive an SMS confirmation shortly.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'REFERENCE NUMBER',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _refNo,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.go('/track'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: svc.color,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                            minimumSize: const Size(0, 42),
                          ),
                          child: Text(
                            'Track Application',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go('/home'),
                        child: Text(
                          'Back to Home',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final stepLabels = ['Personal Info', 'Contact', 'Documents', 'Confirm'];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: AppBackButton(
          onPressed: () async {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              context.pop();
            }
            _saveDraft();
          },
        ),
        title: Text(
          svc.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: List.generate(stepLabels.length, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: i < stepLabels.length - 1 ? 6 : 0),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 5,
                          decoration: BoxDecoration(
                            color: i <= _step ? svc.color : AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stepLabels[i],
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight:
                                i == _step ? FontWeight.w700 : FontWeight.w500,
                            color:
                                i <= _step ? svc.color : AppColors.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_step == 0) ..._step0Fields(),
            if (_step == 1) ..._step1Fields(),
            if (_step == 2) _documentsView(),
            if (_step == 3) _confirmView(svc),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ElevatedButton(
            onPressed: _loading ? null : _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: svc.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              minimumSize: const Size(0, 42),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _step < 3 ? 'Continue →' : 'Submit Application',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  List<Widget> _step0Fields() => [
        _Field(label: 'Full Name (as on Ghana Card)', controller: _nameCtrl),
        _Field(
          label: 'Date of Birth',
          controller: _dobCtrl,
          hint: 'DD / MM / YYYY',
          readOnly: true,
          suffixIcon: const Icon(Icons.calendar_month_rounded),
          onTap: _pickDateOfBirth,
        ),
        _Field(
            label: 'Ghana Card Number',
            controller: _ghanacardCtrl,
            hint: 'GHA-000000000-0'),
        _DropdownField(
          label: 'Gender',
          value: _gender,
          items: ['Male', 'Female', 'Prefer not to say'],
          onChanged: (v) => setState(() => _gender = v),
        ),
      ];

  Future<void> _pickDateOfBirth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select date of birth',
    );
    if (selected != null) {
      _dobCtrl.text = DateFormat('dd / MM / yyyy').format(selected);
    }
  }

  List<Widget> _step1Fields() => [
        _Field(
            label: 'Mobile Number',
            controller: _phoneCtrl,
            hint: '0XX XXX XXXX',
            keyboardType: TextInputType.phone),
        _Field(
            label: 'Email Address',
            controller: _emailCtrl,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress),
        _DropdownField(
          label: 'Region',
          value: _region,
          items: _regions,
          onChanged: (v) => setState(() => _region = v),
        ),
        _Field(label: 'District', controller: _districtCtrl),
      ];

  Widget _documentsView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documents required',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload each document as a PDF. A document is ticked only after its PDF is selected.',
            style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ..._documentFields.map(
            (document) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Checkbox(
                value: _documents[document] != null,
                onChanged: null,
              ),
              title: Text(
                _requiredDocuments.contains(document)
                    ? document
                    : '$document (optional)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: _documents[document] == null
                  ? null
                  : Text(
                      _documents[document]!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.ghGreen,
                      ),
                    ),
              trailing: IconButton(
                tooltip: 'Upload PDF',
                mouseCursor: SystemMouseCursors.click,
                icon: const Icon(Icons.upload_file_rounded),
                onPressed: () => _uploadDocument(document),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmView(GovernmentService svc) {
    final rows = [
      ['Service', svc.title],
      ['Applicant', _nameCtrl.text],
      ['Ghana Card No.', _ghanacardCtrl.text],
      ['Mobile', _phoneCtrl.text],
      ['Region', _region ?? ''],
      ['Fee', svc.fee],
      ['Processing Time', svc.duration],
      ['Payment Method', 'Mobile Money (MoMo)'],
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Confirm',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF3F4F6)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    row[0],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      row[1],
                      textAlign: TextAlign.end,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'By submitting, you confirm that all information is accurate and agree to the terms of service of the Republic of Ghana.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hint ?? label,
              suffixIcon: suffixIcon,
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? '$label is required'
                : null,
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: items.contains(value) ? value : null,
            decoration: const InputDecoration(),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
            validator: (value) => value == null || value.isEmpty
              ? '$label is required'
              : null,
          ),
        ],
      ),
    );
  }
}
