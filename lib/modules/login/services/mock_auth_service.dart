import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class MockAuthService implements AuthService {
  UserModel? _currentUser;
  String? _currentToken;

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    await Future.delayed(const Duration(seconds: 2));

    if (request.email == 'admin@touchliga.mx' && request.password == '123456') {
      _currentUser = const UserModel(
        userId: 1,
        participantId: 1,
        organizationId: 1,
        name: 'Roberto Valdez',
        email: 'admin@touchliga.mx',
        photo: '',
        active: true,
        roles: ['Administrador'],
        leagues: [1, 2],
      );

      _currentToken = 'JWT_TOKEN_DEMO';

      return LoginResponseModel(
        success: true,
        message: 'Acceso correcto',
        token: _currentToken!,
        user: _currentUser,
      );
    }

    return const LoginResponseModel(
      success: false,
      message: 'Usuario o contraseña incorrectos',
      token: '',
      user: null,
    );
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _currentToken = null;
  }

  @override
  Future<bool> hasSession() async {
    return _currentToken != null;
  }

  @override
  Future<UserModel?> currentUser() async {
    return _currentUser;
  }

  @override
  Future<String?> currentToken() async {
    return _currentToken;
  }
}
