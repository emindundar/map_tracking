class UserRegisterModel {
  final String email;
  final String password;

  const UserRegisterModel({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class UserLoginModel {
  final String email;
  final String password;

  const UserLoginModel({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}
