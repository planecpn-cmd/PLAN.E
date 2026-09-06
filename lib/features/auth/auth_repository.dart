import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';
import '../../providers/app_providers.dart';

/// OAuth client IDs for the native Google sign-in flow, supplied via
/// --dart-define (same pattern as SUPABASE_URL). The *web* client ID is the
/// audience Supabase verifies the returned ID token against; the iOS client
/// ID is only consumed by the Google SDK on Apple platforms. Android needs
/// neither here — it matches on the SHA-1 + package registered in the
/// Android OAuth client.
class GoogleAuthConfig {
  static const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
}

/// Sign in with Apple only makes sense — and is only enabled — on Apple's
/// own platforms; Android has no Apple account integration to offer.
bool get isApplePlatform =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
      },
    );
    // public.handle_new_user() creates the profile inside the database. Do
    // not perform a client upsert here: with email confirmation enabled there
    // is no authenticated session until OTP verification, so that write must
    // remain unavailable under RLS.
    return response;
  }

  Future<AuthResponse> signInWithEmail({
    required String emailOrPhone,
    required String password,
  }) async {
    final input = emailOrPhone.trim();
    if (input.contains('@')) {
      return await _client.auth.signInWithPassword(
        email: input,
        password: password,
      );
    } else {
      return await _client.auth.signInWithPassword(
        phone: input,
        password: password,
      );
    }
  }

  Future<void> sendPasswordReset(String emailOrPhone) async {
    final input = emailOrPhone.trim();
    if (input.contains('@')) {
      await _client.auth.resetPasswordForEmail(
        input,
        redirectTo: AppSupabaseClient.authRedirectUrl,
      );
    } else {
      // For phone reset OTP if needed
      await _client.auth.signInWithOtp(phone: input);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Launches the provider's consent screen in the system browser. Supabase's
  /// own project URL (not this app's domain) is the OAuth callback the
  /// provider redirects to, so this works with no domain of our own. The
  /// browser then hands back to [AppSupabaseClient.authRedirectUrl], which
  /// supabase_flutter picks up automatically to complete the session.
  Future<bool> signInWithOAuth(OAuthProvider provider) {
    return _client.auth.signInWithOAuth(
      provider,
      redirectTo: AppSupabaseClient.authRedirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  /// Native Google sign-in: the OS account picker appears in-app (no browser,
  /// no redirect deep link), and the Google ID token it returns is exchanged
  /// for a Supabase session via signInWithIdToken. Returns false when the user
  /// dismisses the picker without choosing an account.
  Future<bool> signInWithGoogleNative() async {
    if (GoogleAuthConfig.webClientId.isEmpty) {
      throw StateError(
        'GOOGLE_WEB_CLIENT_ID is empty. Provide it with --dart-define.',
      );
    }
    final googleSignIn = GoogleSignIn(
      clientId: GoogleAuthConfig.iosClientId.isEmpty
          ? null
          : GoogleAuthConfig.iosClientId,
      serverClientId: GoogleAuthConfig.webClientId,
    );
    // Clear any cached account so the picker is always shown rather than
    // silently reusing a stale selection.
    await googleSignIn.signOut();
    final account = await googleSignIn.signIn();
    if (account == null) return false;

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw const AuthException('Google did not return an ID token.');
    }
    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: auth.accessToken,
    );
    return true;
  }

  Future<AuthResponse> verifySignupOtp({
    required String email,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      type: OtpType.signup,
      email: email.trim(),
      token: token.trim(),
    );
  }

  Future<AuthResponse> verifyRecoveryOtp({
    required String email,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      type: OtpType.recovery,
      email: email.trim(),
      token: token.trim(),
    );
  }

  Future<void> resendSignupOtp(String email) {
    return _client.auth.resend(type: OtpType.signup, email: email.trim());
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// A recovery session is intentionally short-lived. Clearing it after the
  /// password update prevents the recovery auth event from being replayed on
  /// resume and sending the user back to verification.
  Future<void> completePasswordRecovery(String newPassword) async {
    await updatePassword(newPassword);
    await _client.auth.signOut(scope: SignOutScope.local);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

/// Converts provider/network failures into messages that are useful to an app
/// user without exposing transport implementation details.
String friendlyAuthError(Object error) {
  final raw = error is AuthException ? error.message : error.toString();
  final normalized = raw.toLowerCase();
  if (normalized.contains('error sending confirmation email') ||
      normalized.contains('could not send email')) {
    return 'We couldn’t send the verification email. Please try again later or contact support.';
  }
  if (normalized.contains('invalid login credentials')) {
    return 'Invalid email or password. Please try again.';
  }
  if (normalized.contains('email rate limit exceeded') ||
      normalized.contains('over_email_send_rate_limit')) {
    return 'Too many verification emails were requested. Please wait before trying again.';
  }
  if (normalized.contains('socketexception') ||
      normalized.contains('connection refused') ||
      normalized.contains('failed host lookup') ||
      normalized.contains('network is unreachable') ||
      normalized.contains('connection timed out')) {
    return 'We couldn’t connect to the server. Check your connection and try again.';
  }
  return raw;
}

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  AuthState copyWith({bool? isLoading, String? errorMessage, bool? isSuccess}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  void clearError() {
    state = state.copyWith(errorMessage: null, isSuccess: false);
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSuccess: false,
    );
    try {
      await _repository.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: friendlyAuthError(e),
      );
      return false;
    }
  }

  Future<bool> signIn({
    required String emailOrPhone,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSuccess: false,
    );
    try {
      await _repository.signInWithEmail(
        emailOrPhone: emailOrPhone,
        password: password,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: friendlyAuthError(e),
      );
      return false;
    }
  }

  Future<bool> resetPassword(String emailOrPhone) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSuccess: false,
    );
    try {
      await _repository.sendPasswordReset(emailOrPhone);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: friendlyAuthError(e),
      );
      return false;
    }
  }

  Future<void> signInWithOAuth(OAuthProvider provider) async {
    state = state.copyWith(errorMessage: null);
    try {
      await _repository.signInWithOAuth(provider);
    } catch (e) {
      state = state.copyWith(errorMessage: friendlyAuthError(e));
    }
  }

  /// Returns true when a Supabase session was established, false when the user
  /// dismissed the Google account picker. On failure the message lands in
  /// [AuthState.errorMessage].
  Future<bool> signInWithGoogleNative() async {
    state = state.copyWith(errorMessage: null);
    try {
      return await _repository.signInWithGoogleNative();
    } catch (e) {
      state = state.copyWith(errorMessage: friendlyAuthError(e));
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String token,
    required bool isRecovery,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSuccess: false,
    );
    try {
      if (isRecovery) {
        await _repository.verifyRecoveryOtp(email: email, token: token);
      } else {
        await _repository.verifySignupOtp(email: email, token: token);
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: friendlyAuthError(e),
      );
      return false;
    }
  }

  Future<bool> resendOtp({
    required String email,
    required bool isRecovery,
  }) async {
    state = state.copyWith(errorMessage: null);
    try {
      if (isRecovery) {
        await _repository.sendPasswordReset(email);
      } else {
        await _repository.resendSignupOtp(email);
      }
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: friendlyAuthError(e));
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSuccess: false,
    );
    try {
      await _repository.completePasswordRecovery(newPassword);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: friendlyAuthError(e),
      );
      return false;
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
