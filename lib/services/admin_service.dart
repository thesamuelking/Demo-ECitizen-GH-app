import 'package:dio/dio.dart';
import 'package:ghanaserve/models/service_model.dart';
import 'package:ghanaserve/services/api_client.dart';

class AdminApplication {
  final String id;
  final String service;
  final String refNo;
  final String date;
  final ApplicationStatus status;
  final String applicantName;
  final String applicantEmail;
  final Map<String, dynamic> formData;
  final List<Map<String, dynamic>> documents;

  const AdminApplication(
      {required this.id,
      required this.service,
      required this.refNo,
      required this.date,
      required this.status,
      required this.applicantName,
      required this.applicantEmail,
      required this.formData,
      required this.documents});

  factory AdminApplication.fromJson(Map<String, dynamic> json) {
    final applicant =
        Map<String, dynamic>.from(json['applicant'] as Map? ?? {});
    return AdminApplication(
      id: json['id'] as String,
      service: json['service'] as String,
      refNo: json['ref_no'] as String,
      date: json['date'] as String,
      status: ApplicationStatus.values.byName(json['status'] as String),
      applicantName: applicant['full_name'] as String? ?? 'Unknown applicant',
      applicantEmail: applicant['email'] as String? ?? '',
      formData: Map<String, dynamic>.from(json['form_data'] as Map? ?? {}),
        documents: (json['documents'] as List<dynamic>? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(),
    );
  }
}

class AdminService {
  final ApiClient _api;
  AdminService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<AdminApplication>> fetchApplications(
      {String? service, String? status}) async {
    try {
      final response = await _api.dio
          .get('/applications/admin/applications/', queryParameters: {
        if (service != null && service.isNotEmpty) 'service': service,
        if (status != null && status.isNotEmpty) 'status': status,
      });
      final rows = response.data as List<dynamic>;
      return rows
          .map((item) =>
              AdminApplication.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<AdminApplication> updateStatus(
      String id, ApplicationStatus status) async {
    try {
      final response = await _api.dio.patch(
          '/applications/admin/applications/$id/',
          data: {'status': status.name});
      return AdminApplication.fromJson(
          Map<String, dynamic>.from(response.data));
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }
}
