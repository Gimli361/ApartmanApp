/// Arıza modeli — backend ArizaDetailDto/ArizaListDto ile eşleşir
class ArizaModel {
  final int id;
  final String baslik;
  final String aciklama;
  final ArizaDurum durum;
  final ArizaOncelik oncelik;
  final int bildirenId;
  final String bildirenAdSoyad;
  final String bildirenDaireNo;
  final DateTime tarih;
  final String? blokNo;
  final String? redNedeni;
  final int takipciSayisi;
  final bool kullaniciTakipEdiyor;

  const ArizaModel({
    required this.id,
    required this.baslik,
    required this.aciklama,
    required this.durum,
    required this.oncelik,
    required this.bildirenId,
    required this.bildirenAdSoyad,
    required this.bildirenDaireNo,
    required this.tarih,
    this.blokNo,
    this.redNedeni,
    this.takipciSayisi = 0,
    this.kullaniciTakipEdiyor = false,
  });

  factory ArizaModel.fromJson(Map<String, dynamic> json) {
    return ArizaModel(
      id: json['id'] as int,
      baslik: json['baslik'] as String,
      aciklama: json['aciklama'] as String? ?? '',
      durum: ArizaDurum.fromString(json['durum'].toString()),
      oncelik: ArizaOncelik.fromString(json['oncelik'].toString()),
      bildirenId: json['bildirenId'] as int? ?? 0,
      bildirenAdSoyad: json['bildirenAdSoyad'] as String? ?? '',
      bildirenDaireNo: json['bildirenDaireNo'] as String? ?? '',
      tarih: DateTime.parse(json['tarih'] as String),
      blokNo: json['blokNo'] as String?,
      redNedeni: json['redNedeni'] as String?,
      takipciSayisi: json['takipciSayisi'] as int? ?? 0,
      kullaniciTakipEdiyor: json['kullaniciTakipEdiyor'] as bool? ?? false,
    );
  }

  ArizaModel copyWith({
    ArizaDurum? durum,
    int? takipciSayisi,
    bool? kullaniciTakipEdiyor,
    String? redNedeni,
  }) {
    return ArizaModel(
      id: id,
      baslik: baslik,
      aciklama: aciklama,
      durum: durum ?? this.durum,
      oncelik: oncelik,
      bildirenId: bildirenId,
      bildirenAdSoyad: bildirenAdSoyad,
      bildirenDaireNo: bildirenDaireNo,
      tarih: tarih,
      blokNo: blokNo,
      redNedeni: redNedeni ?? this.redNedeni,
      takipciSayisi: takipciSayisi ?? this.takipciSayisi,
      kullaniciTakipEdiyor: kullaniciTakipEdiyor ?? this.kullaniciTakipEdiyor,
    );
  }
}

/// Takip durumu modeli — backend TakipDurumuDto ile eşleşir
class TakipDurumuModel {
  final bool takipEdiyor;
  final int takipciSayisi;

  const TakipDurumuModel({
    required this.takipEdiyor,
    required this.takipciSayisi,
  });

  factory TakipDurumuModel.fromJson(Map<String, dynamic> json) {
    return TakipDurumuModel(
      takipEdiyor: json['takipEdiyor'] as bool? ?? false,
      takipciSayisi: json['takipciSayisi'] as int? ?? 0,
    );
  }
}

enum ArizaDurum {
  beklemede,
  inceleniyor,
  tamamlandi,
  reddedildi;

  static ArizaDurum fromString(String v) => switch (v) {
        'Inceleniyor' => inceleniyor,
        'Tamamlandi' => tamamlandi,
        'Reddedildi' => reddedildi,
        _ => beklemede,
      };

  String toApiString() => switch (this) {
        beklemede => 'Beklemede',
        inceleniyor => 'Inceleniyor',
        tamamlandi => 'Tamamlandi',
        reddedildi => 'Reddedildi',
      };

  String get label => switch (this) {
        beklemede => 'Beklemede',
        inceleniyor => 'İnceleniyor',
        tamamlandi => 'Tamamlandı',
        reddedildi => 'Reddedildi',
      };
}

enum ArizaOncelik {
  dusuk,
  orta,
  yuksek,
  kritik;

  static ArizaOncelik fromString(String v) => switch (v) {
        'Dusuk' => dusuk,
        'Yuksek' => yuksek,
        'Kritik' => kritik,
        _ => orta,
      };

  String toApiString() => switch (this) {
        dusuk => 'Dusuk',
        orta => 'Orta',
        yuksek => 'Yuksek',
        kritik => 'Kritik',
      };

  String get label => switch (this) {
        dusuk => 'Düşük',
        orta => 'Orta',
        yuksek => 'Yüksek',
        kritik => 'Kritik',
      };
}
