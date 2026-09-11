/// All form field validators for the auth flow.
/// Each returns null if valid, or an error string if invalid.
class AuthValidators {
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required';
    if (value.trim().length < 3) return 'Name must be at least 3 characters';
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
      return 'Name may only contain letters, spaces, and hyphens';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Email address is required';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$');
    if (!emailRegex.hasMatch(value.trim()))
      return 'Enter a valid email address';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Mobile number is required';
    final digits = value.replaceAll(RegExp(r'[\s\-()]'), '');
    if (!RegExp(r'^(?:\+233|0)[2-9]\d{8}$').hasMatch(digits)) {
      return 'Enter a valid Ghanaian mobile number (e.g. 024 123 4567)';
    }
    return null;
  }

  static String? ghanacardOptional(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(r'^GHA-\d{9}-\d$').hasMatch(value.trim().toUpperCase())) {
      return 'Format must be GHA-000000000-0';
    }
    return null;
  }

  static String? ghanacard(String? value) => ghanacardOptional(value);

  static String? ghanacardRequired(String? value) {
    final optionalError = ghanacardOptional(value);
    if (optionalError != null) return optionalError;
    if (value == null || value.trim().isEmpty)
      return 'Ghana Card number is required';
    return null;
  }

  /// Used on the login screen — only checks that it's non-empty.
  static String? passwordLogin(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  /// Full strength validation for the sign-up screen.
  static String? passwordSignUp(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }
}
