class SakinOzetModel {
  final int id;
  final String adSoyad;
  final String email;
  final String rol;

  const SakinOzetModel({
    required this.id,
    required this.adSoyad,
    required this.email,
    required this.rol,
  });

  factory SakinOzetModel.fromJson(Map<String, dynamic> json) {
    return SakinOzetModel(
      id: json['id'] as int,
      adSoyad: json['adSoyad'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rol: json['rol'] as String? ?? '',
    );
  }
}

class DaireModel {
  final int id;
  final int blokId;
  final String daireNo;
  final SakinOzetModel? sakin;

  const DaireModel({
    required this.id,
    required this.blokId,
    required this.daireNo,
    this.sakin,
  });

  factory DaireModel.fromJson(Map<String, dynamic> json) {
    return DaireModel(
      id: json['id'] as int,
      blokId: json['blokId'] as int? ?? 0,
      daireNo: json['daireNo'] as String,
      sakin: json['sakin'] != null
          ? SakinOzetModel.fromJson(json['sakin'] as Map<String, dynamic>)
          : null,
    );
  }
}
