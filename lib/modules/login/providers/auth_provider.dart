import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/services/push_notification_service.dart';
import '../models/login_request_model.dart';
import '../services/api_auth_service.dart';
import '../services/auth_service.dart';
import 'login_state.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return ApiAuthService(
    apiClient: ref.read(apiClientProvider),
    baseUrl: ApiConstants.baseUrl,
  );
});

final authProvider = StateNotifierProvider<AuthNotifier, LoginState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

class AuthNotifier extends StateNotifier<LoginState> {
  AuthNotifier(this._service) : super(const LoginState());

  final AuthService _service;

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(loading: true, errorMessage: null);

    try {
      final response = await _service.login(
        LoginRequestModel(email: email, password: password),
      );

      if (!response.success) {
        state = state.copyWith(
          loading: false,
          authenticated: false,
          errorMessage: response.message,
        );
        return false;
      }

      state = state.copyWith(
        loading: false,
        authenticated: true,
        token: response.token,
        user: response.user,
        errorMessage: null,
      );

      // No se espera a que termine (no debe retrasar el login si
      // Firebase tarda) — y solo hace algo real en Android.
      PushNotificationService.inicializar();

      return true;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        authenticated: false,
        errorMessage: e.toString(),
      );

      return false;
    }
  }

  Future<void> checkSession() async {
    state = state.copyWith(loading: true, errorMessage: null);

    try {
      final hasSession = await _service.hasSession();

      if (!hasSession) {
        state = state.copyWith(loading: false, authenticated: false);
        return;
      }

      final user = await _service.currentUser();
      final token = await _service.currentToken();

      state = state.copyWith(
        loading: false,
        authenticated: token != null && token.isNotEmpty,
        token: token,
        user: user,
        errorMessage: null,
      );

      if (token != null && token.isNotEmpty) {
        PushNotificationService.inicializar();
      }
    } catch (e) {
      state = state.copyWith(
        loading: false,
        authenticated: false,
        token: null,
        user: null,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await PushNotificationService.eliminarDelBackend();
    await _service.logout();
    state = const LoginState();
  }
}
