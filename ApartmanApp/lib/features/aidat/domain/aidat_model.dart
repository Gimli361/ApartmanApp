/// Aidat modeli — backend AidatListDto ile eşleşir
class AidatModel {
  final int id;
  final int kullaniciId;
  final String kullaniciAdSoyad;
  final String daireNo;
  final double tutar;
  final int ay;
  final int yil;
  final OdemeDurumu odemeDurumu;
  final DateTime? odemeTarihi;

  const AidatModel({
    required this.id,
    required this.kullaniciId,
    required this.kullaniciAdSoyad,
    required this.daireNo,
    required this.tutar,
    required this.ay,
    required this.yil,
    required this.odemeDurumu,
    this.odemeTarihi,
  });

  factory AidatModel.fromJson(Map<String, dynamic> json) {
    return AidatModel(
      id: json['id'] as int,
      kullaniciId: json['kullaniciId'] as int,
      kullaniciAdSoyad: json['kullaniciAdSoyad'] as String? ?? '',
      daireNo: json['daireNo'] as String? ?? '',
      tutar: (json['tutar'] as num).toDouble(),
      ay: json['ay'] as int,
      yil: json['yil'] as int,
      odemeDurumu: _parseDurum(json['odemeDurumu']),
      odemeTarihi: json['odemeTarihi'] != null
          ? DateTime.parse(json['odemeTarihi'] as String)
          : null,
    );
  }

  AidatModel copyWith({OdemeDurumu? odemeDurumu, DateTime? odemeTarihi}) {
    return AidatModel(
      id: id,
      kullaniciId: kullaniciId,
      kullaniciAdSoyad: kullaniciAdSoyad,
      daireNo: daireNo,
      tutar: tutar,
      ay: ay,
      yil: yil,
      odemeDurumu: odemeDurumu ?? this.odemeDurumu,
      odemeTarihi: odemeTarihi ?? this.odemeTarihi,
    );
  }
}

enum OdemeDurumu { beklemede, odendi, gecikti }

OdemeDurumu _parseDurum(dynamic value) {
  final s = (value as String?)?.toLowerCase() ?? '';
  return switch (s) {
    'odendi' => OdemeDurumu.odendi,
    'gecikti' => OdemeDurumu.gecikti,
    _ => OdemeDurumu.beklemede,
  };
}
