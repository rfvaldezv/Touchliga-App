import 'user_model.dart';

class LoginResponseModel {
  const LoginResponseModel({
    required this.success,
    required this.message,
    required this.token,
    required this.user,
    this.refreshToken,
    this.expira,
  });

  final bool success;
  final String message;
  final String token;
  final String? refreshToken;
  final DateTime? expira;
  final UserModel? user;

  factory LoginResponseModel.fromApi(Map<String, dynamic> json) {
    return LoginResponseModel(
      success: true,
      message: 'Acceso correcto',
      token: (json['accessToken'] ?? '').toString(),
      refreshToken: json['refreshToken']?.toString(),
      expira: json['expira'] != null
          ? DateTime.tryParse(json['expira'].toString())
          : null,
      user: UserModel(
        userId: json['usuarioId'] ?? 0,
        participantId: 0,
        organizationId: 0,
        name: (json['nombre'] ?? '').toString(),
        email: (json['correo'] ?? '').toString(),
        photo: '',
        active: true,
        roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        leagues: const [],
      ),
    );
  }

  factory LoginResponseModel.error(String message) {
    return LoginResponseModel(
      success: false,
      message: message,
      token: '',
      refreshToken: null,
      expira: null,
      user: null,
    );
  }
}
