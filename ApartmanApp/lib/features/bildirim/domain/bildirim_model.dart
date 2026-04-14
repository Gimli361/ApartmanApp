class BildirimModel {
  final int id;
  final String baslik;
  final String icerik;
  final String tip;
  final DateTime gonderimTarihi;
  final bool okundu;

  const BildirimModel({
    required this.id,
    required this.baslik,
    required this.icerik,
    required this.tip,
    required this.gonderimTarihi,
    required this.okundu,
  });

  factory BildirimModel.fromJson(Map<String, dynamic> json) {
    return BildirimModel(
      id: json['id'] as int,
      baslik: json['baslik'] as String,
      icerik: json['icerik'] as String,
      tip: json['tip'] as String? ?? '',
      gonderimTarihi: DateTime.parse(json['gonderimTarihi'] as String),
      okundu: json['okundu'] as bool,
    );
  }

  BildirimModel copyWith({bool? okundu}) {
    return BildirimModel(
      id: id,
      baslik: baslik,
      icerik: icerik,
      tip: tip,
      gonderimTarihi: gonderimTarihi,
      okundu: okundu ?? this.okundu,
    );
  }
}
