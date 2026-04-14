/// Oylama modeli
class OylamaModel {
  final String id;
  final String soru;
  final List<OylamaSecenek> secenekler;
  final DateTime baslangicTarihi;
  final DateTime bitisTarihi;
  final bool aktif;

  const OylamaModel({
    required this.id,
    required this.soru,
    required this.secenekler,
    required this.baslangicTarihi,
    required this.bitisTarihi,
    required this.aktif,
  });
}

class OylamaSecenek {
  final String id;
  final String metin;
  final int oyCount;

  const OylamaSecenek({
    required this.id,
    required this.metin,
    required this.oyCount,
  });
}
