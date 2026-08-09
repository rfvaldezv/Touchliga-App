import '../../../app/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';

import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class ApiAuthService implements AuthService {
  ApiAuthService({required ApiClient apiClient, String? baseUrl})
    : _apiClient = apiClient,
      baseUrl = baseUrl ?? ApiConstants.baseUrl;

  final ApiClient _apiClient;
  final String baseUrl;

  UserModel? _currentUser;
  String? _currentToken;

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      body: request.toJson(),
    );

    if (!response.success || !response.hasData) {
      return LoginResponseModel.error(
        response.message ?? 'No fue posible iniciar sesión.',
      );
    }

    final login = LoginResponseModel.fromApi(response.data!);

    _currentToken = login.token;
    _currentUser = login.user;

    // Persistir sesión completa (token + usuario)
    await SecureStorage.saveAccessToken(login.token);

    if (login.refreshToken != null && login.refreshToken!.isNotEmpty) {
      await SecureStorage.saveRefreshToken(login.refreshToken!);
    }

    if (login.user != null) {
      await SecureStorage.saveUser(login.user!.toJson());
    }

    return login;
  }

  @override
  Future<void> logout() async {
    final refreshToken = await SecureStorage.getRefreshToken();

    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _apiClient.post(
          ApiConstants.logout,
          body: {'refreshToken': refreshToken},
        );
      } catch (_) {
        // Si el backend no responde (sin conexión, etc.), igual
        // cerramos la sesión localmente — no dejamos al usuario
        // atrapado en la app por un problema de red.
      }
    }

    _currentToken = null;
    _currentUser = null;

    await SecureStorage.clearSession();
  }

  @override
  Future<bool> hasSession() async {
    final token = await SecureStorage.getAccessToken();

    _currentToken = token;

    return token != null && token.isNotEmpty;
  }

  @override
  Future<UserModel?> currentUser() async {
    if (_currentUser != null) return _currentUser;

    final storedUser = await SecureStorage.getUser();

    if (storedUser != null) {
      _currentUser = UserModel.fromJson(storedUser);
    }

    return _currentUser;
  }

  @override
  Future<String?> currentToken() async {
    _currentToken ??= await SecureStorage.getAccessToken();

    return _currentToken;
  }
}
