import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';
import '../../providers/app_providers.dart';

/// Sign in with Apple only makes sense — and is only enabled — on Apple's
/// own platforms; Android has no Apple account integration to offer.
bool get isApplePlatform =>
    defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

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

    if (response.user != null) {
      // Upsert profile record
      await _client.from('profiles').upsert({
        'id': response.user!.id,
        'full_name': fullName.trim(),
        if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    }

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
      await _client.auth.resetPasswordForEmail(input);
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
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
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
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
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
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signIn({
    required String emailOrPhone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      await _repository.signInWithEmail(
        emailOrPhone: emailOrPhone,
        password: password,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> resetPassword(String emailOrPhone) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      await _repository.sendPasswordReset(emailOrPhone);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> signInWithOAuth(OAuthProvider provider) async {
    state = state.copyWith(errorMessage: null);
    try {
      await _repository.signInWithOAuth(provider);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String token,
    required bool isRecovery,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      if (isRecovery) {
        await _repository.verifyRecoveryOtp(email: email, token: token);
      } else {
        await _repository.verifySignupOtp(email: email, token: token);
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> resendOtp({required String email, required bool isRecovery}) async {
    state = state.copyWith(errorMessage: null);
    try {
      if (isRecovery) {
        await _repository.sendPasswordReset(email);
      } else {
        await _repository.resendSignupOtp(email);
      }
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      await _repository.updatePassword(newPassword);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
