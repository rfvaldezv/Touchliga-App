import '../models/user_model.dart';

class LoginState {
  const LoginState({
    this.loading = false,
    this.authenticated = false,
    this.user,
    this.token,
    this.errorMessage,
  });

  final bool loading;
  final bool authenticated;
  final UserModel? user;
  final String? token;
  final String? errorMessage;

  LoginState copyWith({
    bool? loading,
    bool? authenticated,
    UserModel? user,
    String? token,
    String? errorMessage,
  }) {
    return LoginState(
      loading: loading ?? this.loading,
      authenticated: authenticated ?? this.authenticated,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage,
    );
  }
}
