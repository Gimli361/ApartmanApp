/// Oylama liste özeti
class OylamaModel {
  final int id;
  final String baslik;
  final String? aciklama;
  final DateTime baslangicTarihi;
  final DateTime bitisTarihi;
  final bool aktifMi;
  final int toplamOySayisi;
  final bool kullaniciOyKullandi;

  const OylamaModel({
    required this.id,
    required this.baslik,
    this.aciklama,
    required this.baslangicTarihi,
    required this.bitisTarihi,
    required this.aktifMi,
    required this.toplamOySayisi,
    required this.kullaniciOyKullandi,
  });

  factory OylamaModel.fromJson(Map<String, dynamic> json) {
    return OylamaModel(
      id: json['id'] as int,
      baslik: json['baslik'] as String,
      aciklama: json['aciklama'] as String?,
      baslangicTarihi: DateTime.parse(json['baslangicTarihi'] as String),
      bitisTarihi: DateTime.parse(json['bitisTarihi'] as String),
      aktifMi: json['aktifMi'] as bool,
      toplamOySayisi: json['toplamOySayisi'] as int? ?? 0,
      kullaniciOyKullandi: json['kullaniciOyKullandi'] as bool? ?? false,
    );
  }

  bool get suresiDoldu => bitisTarihi.isBefore(DateTime.now());
  bool get acikMi => aktifMi && !suresiDoldu;
}

/// Oylama detayı — seçeneklerle birlikte
class OylamaDetailModel {
  final int id;
  final String baslik;
  final String? aciklama;
  final DateTime baslangicTarihi;
  final DateTime bitisTarihi;
  final bool aktifMi;
  final int olusturanId;
  final int toplamOySayisi;
  final bool kullaniciOyKullandi;
  final int? kullaniciSecenekId;
  final List<OylamaSecenekModel> secenekler;

  const OylamaDetailModel({
    required this.id,
    required this.baslik,
    this.aciklama,
    required this.baslangicTarihi,
    required this.bitisTarihi,
    required this.aktifMi,
    required this.olusturanId,
    required this.toplamOySayisi,
    required this.kullaniciOyKullandi,
    this.kullaniciSecenekId,
    required this.secenekler,
  });

  factory OylamaDetailModel.fromJson(Map<String, dynamic> json) {
    return OylamaDetailModel(
      id: json['id'] as int,
      baslik: json['baslik'] as String,
      aciklama: json['aciklama'] as String?,
      baslangicTarihi: DateTime.parse(json['baslangicTarihi'] as String),
      bitisTarihi: DateTime.parse(json['bitisTarihi'] as String),
      aktifMi: json['aktifMi'] as bool,
      olusturanId: json['olusturanId'] as int,
      toplamOySayisi: json['toplamOySayisi'] as int? ?? 0,
      kullaniciOyKullandi: json['kullaniciOyKullandi'] as bool? ?? false,
      kullaniciSecenekId: json['kullaniciSecenekId'] as int?,
      secenekler: (json['secenekler'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(OylamaSecenekModel.fromJson)
          .toList(),
    );
  }

  bool get suresiDoldu => bitisTarihi.isBefore(DateTime.now());
  bool get acikMi => aktifMi && !suresiDoldu;
}

class OylamaSecenekModel {
  final int id;
  final String metin;
  final int oySayisi;
  final double oranYuzde;

  const OylamaSecenekModel({
    required this.id,
    required this.metin,
    required this.oySayisi,
    required this.oranYuzde,
  });

  factory OylamaSecenekModel.fromJson(Map<String, dynamic> json) {
    return OylamaSecenekModel(
      id: json['id'] as int,
      metin: json['metin'] as String,
      oySayisi: json['oySayisi'] as int? ?? 0,
      oranYuzde: (json['oranYuzde'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
