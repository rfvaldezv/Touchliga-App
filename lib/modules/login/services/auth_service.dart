import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';

abstract class AuthService {
  /// Autentica al usuario
  Future<LoginResponseModel> login(LoginRequestModel request);

  /// Cierra la sesión actual
  Future<void> logout();

  /// Indica si existe una sesión válida
  Future<bool> hasSession();

  /// Devuelve el usuario autenticado
  Future<UserModel?> currentUser();

  /// Devuelve el token actual
  Future<String?> currentToken();
}
