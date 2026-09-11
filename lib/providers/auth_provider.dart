import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghanaserve/models/auth_models.dart';
import 'package:ghanaserve/services/api_client.dart';
import 'package:ghanaserve/services/auth_service.dart';
import 'package:ghanaserve/providers/notification_provider.dart';
import 'package:ghanaserve/providers/applications_provider.dart';

// ── Service provider ─────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ── Auth state ───────────────────────────────────────────────────────────────

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final CitizenUser? user;
  final String? error;

  const AuthState({
    required this.status,
    this.user,
    this.error,
  });

  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);
  AuthState.authenticated(CitizenUser user)
      : this(status: AuthStatus.authenticated, user: user);
  AuthState.error(String message)
      : this(status: AuthStatus.unauthenticated, error: message);

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<AuthState> {
  late AuthService _service;

  @override
  Future<AuthState> build() async {
    _service = ref.read(authServiceProvider);
    final user = await _service.getSessionUser();
    if (user != null) return AuthState.authenticated(user);
    return const AuthState.unauthenticated();
  }

  /// Creates a new citizen account and signs in.
  Future<bool> signUp(SignUpRequest request) async {
    state = const AsyncData(AuthState.loading());
    try {
      final result = await _service.signUp(request);
      state = AsyncData(AuthState.authenticated(result.user));
      await ref.read(appNotificationsProvider.notifier).addNotification(
          userId: result.user.id,
          id: 'login-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Welcome to E-citizen GH',
          message: 'Your account was created and you signed in.');
      return true;
    } on AuthException catch (e) {
      state = AsyncData(AuthState.error(e.message));
      return false;
    } catch (e) {
      state = AsyncData(AuthState.error('An unexpected error occurred.'));
      return false;
    }
  }

  /// Signs in with email + password.
  Future<bool> signIn(SignInRequest request) async {
    state = const AsyncData(AuthState.loading());
    try {
      final result = await _service.signIn(request);
      state = AsyncData(AuthState.authenticated(result.user));
      await ref.read(appNotificationsProvider.notifier).addNotification(
          userId: result.user.id,
          id: 'login-${DateTime.now().millisecondsSinceEpoch}',
          title: 'New sign in',
          message: 'You signed in successfully.');
      return true;
    } on AuthException catch (e) {
      state = AsyncData(AuthState.error(e.message));
      return false;
    } catch (e) {
      state = AsyncData(AuthState.error('An unexpected error occurred.'));
      return false;
    }
  }

  Future<bool> resetPassword(ResetPasswordRequest request) async {
    state = const AsyncData(AuthState.loading());
    try {
      await _service.resetPassword(request);
      state = const AsyncData(AuthState.unauthenticated());
      return true;
    } on AuthException catch (e) {
      state = AsyncData(AuthState.error(e.message));
      return false;
    } catch (_) {
      state = AsyncData(AuthState.error('Unable to reset your password right now.'));
      return false;
    }
  }

  Future<bool> signInAsAdmin(SignInRequest request) async {
    state = const AsyncData(AuthState.loading());
    try {
      final result = await _service.signInAsAdmin(request);
      if (!result.user.isStaff) {
        throw const AuthException(
            'This account is not authorized for the staff portal.');
      }
      state = AsyncData(AuthState.authenticated(result.user));
      return true;
    } on AuthException catch (e) {
      state = AsyncData(AuthState.error(e.message));
      return false;
    } catch (_) {
      state = AsyncData(AuthState.error('An unexpected error occurred.'));
      return false;
    }
  }

  Future<bool> signInWithGhanaCard(GhanaCardSignInRequest request) async {
    state = const AsyncData(AuthState.loading());
    try {
      final result = await _service.signInWithGhanaCard(request);
      state = AsyncData(AuthState.authenticated(result.user));
      await ref.read(appNotificationsProvider.notifier).addNotification(
          userId: result.user.id,
          id: 'login-${DateTime.now().millisecondsSinceEpoch}',
          title: 'New sign in',
          message: 'You signed in successfully with Ghana Card.');
      return true;
    } on AuthException catch (e) {
      state = AsyncData(AuthState.error(e.message));
      return false;
    } catch (_) {
      state = AsyncData(AuthState.error('An unexpected error occurred.'));
      return false;
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    String? profilePhoto,
  }) async {
    final current = state.valueOrNull?.user;
    if (current == null) return false;
    try {
      final requestedPhoto = profilePhoto;
      var user = await _service.updateUser(current.copyWith(
        fullName: fullName,
        email: email,
        phone: phone,
        profilePhoto: profilePhoto,
      ));
      // Some deployments omit the photo field in the PATCH response. Keep the
      // photo the user just selected visible until the next full user fetch.
      if (requestedPhoto != null && user.profilePhoto == null) {
        user = CitizenUser(
          id: user.id,
          fullName: user.fullName,
          email: user.email,
          phone: user.phone,
          ghanacardNumber: user.ghanacardNumber,
          hasGhanaCard: user.hasGhanaCard,
          profilePhoto: requestedPhoto,
          isVerified: user.isVerified,
          isStaff: user.isStaff,
          createdAt: user.createdAt,
        );
      }
      state = AsyncData(AuthState.authenticated(user));
      return true;
    } on AuthException {
      return false;
    }
  }

  Future<String?> verifyAccount(VerifyAccountRequest request) async {
    final current = state.valueOrNull?.user;
    if (current == null) return 'Please sign in again.';
    try {
      final user = await _service.verifyAccount(request);
      state = AsyncData(AuthState.authenticated(user));
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unable to verify your account right now.';
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _service.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unable to change your password right now.';
    }
  }

  /// Signs out and clears the session.
  Future<void> signOut() async {
    await _service.signOut();
    ref.invalidate(applicationsProvider);
    ref.invalidate(appNotificationsProvider);
    state = const AsyncData(AuthState.unauthenticated());
  }

  /// Clears any error message without changing auth status.
  void clearError() {
    final current = state.valueOrNull;
    if (current?.error != null) {
      state = AsyncData(AuthState(status: current!.status, user: current.user));
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
