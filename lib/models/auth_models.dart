class CitizenUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String ghanacardNumber;
  final bool hasGhanaCard;
  final String? profilePhoto;
  final bool isVerified;
  final bool isStaff;
  final String serviceDepartment;
  final DateTime createdAt;

  const CitizenUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.ghanacardNumber,
    required this.hasGhanaCard,
    this.profilePhoto,
    required this.isVerified,
    this.isStaff = false,
    this.serviceDepartment = '',
    required this.createdAt,
  });

  factory CitizenUser.fromJson(Map<String, dynamic> json) => CitizenUser(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        ghanacardNumber: json['ghanacard_number'] as String? ?? '',
        hasGhanaCard: json['has_ghanacard'] as bool? ??
            (json['ghanacard_number'] as String? ?? '').isNotEmpty,
        profilePhoto: json['profile_photo'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
        isStaff: json['is_staff'] as bool? ?? false,
        serviceDepartment: json['service_department'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'ghanacard_number': ghanacardNumber,
        'has_ghanacard': hasGhanaCard,
        'profile_photo': profilePhoto,
        'is_verified': isVerified,
        'is_staff': isStaff,
        'service_department': serviceDepartment,
        'created_at': createdAt.toIso8601String(),
      };

  CitizenUser copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? profilePhoto,
    bool? isVerified,
  }) =>
      CitizenUser(
        id: id,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        ghanacardNumber: ghanacardNumber,
        hasGhanaCard: hasGhanaCard,
        profilePhoto: profilePhoto ?? this.profilePhoto,
        isVerified: isVerified ?? this.isVerified,
        isStaff: isStaff,
        serviceDepartment: serviceDepartment,
        createdAt: createdAt,
      );
}

class AuthResult {
  final CitizenUser user;
  final String accessToken;
  final String refreshToken;

  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        user: CitizenUser.fromJson(json['user'] as Map<String, dynamic>),
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );
}

class SignUpRequest {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String ghanacardNumber;

  const SignUpRequest({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.ghanacardNumber,
  });

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'ghanacard_number': ghanacardNumber,
      };
}

class SignInRequest {
  final String email;
  final String password;
  final String? serviceDepartment;

  const SignInRequest({
    required this.email,
    required this.password,
    this.serviceDepartment,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        if (serviceDepartment != null) 'service_department': serviceDepartment,
      };

}

class ResetPasswordRequest {
  final String email;
  final String phone;
  final String newPassword;

  const ResetPasswordRequest({
    required this.email,
    required this.phone,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'phone': phone,
        'new_password': newPassword,
      };
}

class GhanaCardSignInRequest {
  final String ghanacardNumber;

  const GhanaCardSignInRequest({required this.ghanacardNumber});

  Map<String, dynamic> toJson() => {'ghanacard_number': ghanacardNumber};
}

class VerifyAccountRequest {
  final String fullName;
  final String ghanacardNumber;

  const VerifyAccountRequest(
      {required this.fullName, required this.ghanacardNumber});

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'ghanacard_number': ghanacardNumber,
      };
}
