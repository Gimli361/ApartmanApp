import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/blok_model.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final binaProvider = FutureProvider<List<BlokModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final res = await api.dio.get('/api/blok/detay');
  final data = (res.data['data'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map(BlokModel.fromJson)
      .toList();
  return data;
});
