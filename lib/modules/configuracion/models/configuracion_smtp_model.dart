class ConfiguracionSmtpModel {
  const ConfiguracionSmtpModel({
    required this.habilitado,
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.fromEmail,
    required this.fromName,
  });

  final bool habilitado;
  final String host;
  final int port;
  final String username;
  final String password;
  final String fromEmail;
  final String fromName;

  factory ConfiguracionSmtpModel.vacia() => const ConfiguracionSmtpModel(
        habilitado: false,
        host: '',
        port: 587,
        username: '',
        password: '',
        fromEmail: '',
        fromName: 'Touchliga',
      );

  factory ConfiguracionSmtpModel.fromJson(Map<String, dynamic> json) {
    return ConfiguracionSmtpModel(
      habilitado: json['habilitado'] as bool? ?? false,
      host: json['host']?.toString() ?? '',
      port: (json['port'] as num?)?.toInt() ?? 587,
      username: json['username']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      fromEmail: json['fromEmail']?.toString() ?? '',
      fromName: json['fromName']?.toString() ?? 'Touchliga',
    );
  }

  Map<String, dynamic> toJson() => {
        'habilitado': habilitado,
        'host': host,
        'port': port,
        'username': username,
        'password': password,
        'fromEmail': fromEmail,
        'fromName': fromName,
      };
}
