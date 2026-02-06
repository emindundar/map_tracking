class UserRegisterModel {
  String? email;
  String? password;

  UserRegisterModel({this.email, this.password});

  UserRegisterModel.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    password = json['password'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['email'] = email;
    data['password'] = password;
    return data;
  }
}

