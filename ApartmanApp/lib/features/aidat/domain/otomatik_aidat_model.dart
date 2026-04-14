class OtomatikAidatModel {
  final int id;
  final int kullaniciId;
  final String kullaniciAdSoyad;
  final String daireNo;
  final double tutar;
  final bool aktifMi;
  final int? sonUretimAy;
  final int? sonUretimYil;

  const OtomatikAidatModel({
    required this.id,
    required this.kullaniciId,
    required this.kullaniciAdSoyad,
    required this.daireNo,
    required this.tutar,
    required this.aktifMi,
    this.sonUretimAy,
    this.sonUretimYil,
  });

  factory OtomatikAidatModel.fromJson(Map<String, dynamic> json) {
    return OtomatikAidatModel(
      id: json['id'] as int,
      kullaniciId: json['kullaniciId'] as int,
      kullaniciAdSoyad: json['kullaniciAdSoyad'] as String? ?? '',
      daireNo: json['daireNo'] as String? ?? '',
      tutar: (json['tutar'] as num).toDouble(),
      aktifMi: json['aktifMi'] as bool,
      sonUretimAy: json['sonUretimAy'] as int?,
      sonUretimYil: json['sonUretimYil'] as int?,
    );
  }

  OtomatikAidatModel copyWith({bool? aktifMi, double? tutar}) {
    return OtomatikAidatModel(
      id: id,
      kullaniciId: kullaniciId,
      kullaniciAdSoyad: kullaniciAdSoyad,
      daireNo: daireNo,
      tutar: tutar ?? this.tutar,
      aktifMi: aktifMi ?? this.aktifMi,
      sonUretimAy: sonUretimAy,
      sonUretimYil: sonUretimYil,
    );
  }
}
