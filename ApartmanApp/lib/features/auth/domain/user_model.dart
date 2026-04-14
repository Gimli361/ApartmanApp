/// Kullanıcı modeli — backend KullaniciListDto ile eşleşir
class UserModel {
  final int id;
  final String adSoyad;
  final String email;
  final UserRole rol;
  final String daireNo;
  final String? blokNo;

  const UserModel({
    required this.id,
    required this.adSoyad,
    required this.email,
    required this.rol,
    required this.daireNo,
    this.blokNo,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      adSoyad: json['adSoyad'] as String,
      email: json['email'] as String,
      rol: _parseRol(json['rol']),
      daireNo: json['daireNo'] as String,
      blokNo: json['blokNo'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'adSoyad': adSoyad,
        'email': email,
        'rol': rol == UserRole.admin ? 1 : 0,
        'daireNo': daireNo,
        'blokNo': blokNo,
      };
}

enum UserRole { admin, sakin }

UserRole _parseRol(dynamic value) {
  if (value is String) return value == 'Admin' ? UserRole.admin : UserRole.sakin;
  if (value is int) return value == 1 ? UserRole.admin : UserRole.sakin;
  return UserRole.sakin;
}
