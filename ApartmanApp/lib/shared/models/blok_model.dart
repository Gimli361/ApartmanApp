import 'daire_model.dart';

class BlokModel {
  final int id;
  final String ad;
  final List<DaireModel> daireler;

  const BlokModel({
    required this.id,
    required this.ad,
    this.daireler = const [],
  });

  factory BlokModel.fromJson(Map<String, dynamic> json) {
    final daireList = (json['daireler'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(DaireModel.fromJson)
        .toList();
    return BlokModel(
      id: json['id'] as int,
      ad: json['ad'] as String,
      daireler: daireList,
    );
  }
}
