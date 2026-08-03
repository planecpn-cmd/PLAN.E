import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/experience.dart';

class SavedRepository {
  final SupabaseClient _client;

  SavedRepository(this._client);

  Future<List<Experience>> getSavedExperiences() async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('saved_experiences')
        .select('experience_id, experiences(*)')
        .eq('user_id', userId);

    final List<dynamic> data = response as List<dynamic>;
    return data
        .map((json) {
          final expJson = json['experiences'] as Map<String, dynamic>?;
          if (expJson == null) return null;
          return Experience.fromJson(expJson);
        })
        .whereType<Experience>()
        .toList();
  }

  Future<bool> isSaved(String experienceId) async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .from('saved_experiences')
        .select()
        .eq('user_id', userId)
        .eq('experience_id', experienceId)
        .maybeSingle();

    return response != null;
  }

  Future<void> toggleSave(String experienceId, bool currentlySaved) async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    if (currentlySaved) {
      await _client
          .from('saved_experiences')
          .delete()
          .eq('user_id', userId)
          .eq('experience_id', experienceId);
    } else {
      await _client.from('saved_experiences').insert({
        'user_id': userId,
        'experience_id': experienceId,
      });
    }
  }
}
