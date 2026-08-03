import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<Profile?> getCurrentProfile() async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? location,
    String? bio,
  }) async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (location != null) updates['location'] = location;
    if (bio != null) updates['bio'] = bio;
    updates['updated_at'] = DateTime.now().toUtc().toIso8601String();

    await _client.from('profiles').update(updates).eq('id', userId);
  }
}
