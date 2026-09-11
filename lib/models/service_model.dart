import 'package:flutter/material.dart';

class GovernmentService {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String emoji;
  final Color color;
  final Color bgColor;
  final String duration;
  final String fee;
  final List<String> steps;
  final List<String> documents;

  const GovernmentService({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.emoji,
    required this.color,
    required this.bgColor,
    required this.duration,
    required this.fee,
    required this.steps,
    required this.documents,
  });

  const GovernmentService.catalog({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.emoji,
    required this.color,
    required this.bgColor,
    this.duration = 'Varies by service',
    this.fee = 'See service provider',
    this.steps = const [
      'Review service requirements',
      'Complete your details',
      'Submit your request',
      'Confirmation issued',
    ],
    this.documents = const ['Ghana Card or valid ID'],
  });
}

enum ApplicationStatus { draft, pending, processing, approved, rejected, ready }

extension ApplicationStatusExtension on ApplicationStatus {
  String get label {
    switch (this) {
      case ApplicationStatus.draft:
        return 'Draft';
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.processing:
        return 'Processing';
      case ApplicationStatus.approved:
        return 'Approved';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.ready:
        return 'Ready';
    }
  }

  Color get color {
    switch (this) {
      case ApplicationStatus.draft:
        return const Color(0xFF6B7280);
      case ApplicationStatus.pending:
        return const Color(0xFFF59E0B);
      case ApplicationStatus.processing:
        return const Color(0xFF3B82F6);
      case ApplicationStatus.approved:
        return const Color(0xFF10B981);
      case ApplicationStatus.rejected:
        return const Color(0xFFDC2626);
      case ApplicationStatus.ready:
        return const Color(0xFF059669);
    }
  }

  Color get bgColor {
    switch (this) {
      case ApplicationStatus.draft:
        return const Color(0xFFF3F4F6);
      case ApplicationStatus.pending:
        return const Color(0xFFFEF3C7);
      case ApplicationStatus.processing:
        return const Color(0xFFEFF6FF);
      case ApplicationStatus.approved:
        return const Color(0xFFD1FAE5);
      case ApplicationStatus.rejected:
        return const Color(0xFFFEE2E2);
      case ApplicationStatus.ready:
        return const Color(0xFFECFDF5);
    }
  }

  int get stepIndex {
    switch (this) {
      case ApplicationStatus.draft:
        return 0;
      case ApplicationStatus.pending:
        return 0;
      case ApplicationStatus.processing:
        return 1;
      case ApplicationStatus.approved:
        return 2;
      case ApplicationStatus.rejected:
        return 2;
      case ApplicationStatus.ready:
        return 3;
    }
  }
}

class CitizenApplication {
  final String id;
  final String service;
  final ApplicationStatus status;
  final String date;
  final String refNo;
  final String serviceId;
  final String serviceDepartment;
  final Map<String, String> formData;
  final Map<String, String> documents;

  const CitizenApplication({
    required this.id,
    required this.service,
    required this.status,
    required this.date,
    required this.refNo,
    this.serviceId = '',
    this.serviceDepartment = '',
    this.formData = const {},
    this.documents = const {},
  });

  factory CitizenApplication.fromJson(Map<String, dynamic> json) =>
      CitizenApplication(
        id: json['id'] as String,
        service: json['service'] as String,
        status: ApplicationStatus.values.byName(json['status'] as String),
        date: json['date'] as String,
        refNo: json['ref_no'] as String,
        serviceId: json['service_id'] as String? ?? '',
        serviceDepartment: json['service_department'] as String? ?? '',
        formData: Map<String, String>.from(json['form_data'] as Map? ?? {}),
        documents: Map<String, String>.from(json['documents'] as Map? ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'service': service,
        'status': status.name,
        'date': date,
        'ref_no': refNo,
        'service_id': serviceId,
        'service_department': serviceDepartment,
        'form_data': formData,
        'documents': documents,
      };
}
