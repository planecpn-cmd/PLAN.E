import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/offline_cache.dart';
import '../models/profile.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<Profile?> getCurrentProfile() async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final cacheKey = 'profile:$userId';
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      final profile = Profile.fromJson(response);
      await OfflineCache.write(cacheKey, profile.toJson());
      return profile;
    } catch (_) {
      final cached = await OfflineCache.read<Profile>(
        cacheKey,
        (json) => Profile.fromJson(json as Map<String, dynamic>),
      );
      if (cached != null) return cached;
      rethrow;
    }
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

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String extension,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in before uploading a profile photo.');
    }

    final normalizedExtension = extension == 'png' || extension == 'webp'
        ? extension
        : 'jpg';
    final contentType = normalizedExtension == 'png'
        ? 'image/png'
        : normalizedExtension == 'webp'
        ? 'image/webp'
        : 'image/jpeg';
    final path = '$userId/avatar.$normalizedExtension';

    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
            cacheControl: '3600',
          ),
        );
    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
    final avatarUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
    await _client
        .from('profiles')
        .update({
          'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId);
    return avatarUrl;
  }
}
