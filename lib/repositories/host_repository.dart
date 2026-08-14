import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/host/host_provider.dart';
import '../models/host_application.dart';

class HostRepository {
  final SupabaseClient _client;

  HostRepository(this._client);

  /// Upload document bytes to private Supabase storage bucket 'host-documents'.
  /// Returns the storage object path in the bucket.
  Future<String> uploadHostDocument({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException(
        'Authentication is required to upload host documents.',
      );
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final normalizedName = fileName.trim().replaceAll(
      RegExp(r'[^A-Za-z0-9._-]'),
      '_',
    );
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(
        fileName,
        'fileName',
        'A valid file name is required.',
      );
    }
    final path = '$userId/${timestamp}_$normalizedName';
    final lowerName = normalizedName.toLowerCase();
    final contentType = lowerName.endsWith('.pdf')
        ? 'application/pdf'
        : lowerName.endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';

    await _client.storage
        .from('host-documents')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: false, contentType: contentType),
        );
    return path;
  }

  /// Submit host application via Edge Function 'submit-host-application'.
  Future<bool> submitHostApplication(HostApplicationData data) async {
    if (_client.auth.currentUser == null) {
      throw const AuthException(
        'Authentication is required to submit a host application.',
      );
    }

    final payload = {
      'fullName': data.fullName,
      'phone': data.phone,
      'district': data.district,
      'bio': data.bio,
      'title': data.experienceTitle,
      'category': data.category,
      'durationHours': data.durationHours,
      'maxGroupSize': data.maxGroupSize,
      'pricePaisa': data.pricePaisa,
      'description': data.description,
      'idType': data.idType,
      'idNumber': data.idNumber,
      'verificationDocPath': data.verificationDocPath,
      'bankName': data.bankName,
      'accountName': data.accountName,
      'accountNumber': data.accountNumber,
      'branch': data.branch,
    };

    final response = await _client.functions.invoke(
      'submit-host-application',
      body: payload,
    );
    if (response.status != 200 && response.status != 201) {
      final data = response.data;
      final message = data is Map<String, dynamic>
          ? data['error']?.toString()
          : null;
      throw StateError(message ?? 'Host application submission failed.');
    }
    return true;
  }

  /// Fetch host application for the logged-in user.
  Future<HostApplication?> getHostApplication() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('host_applications')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return HostApplication.fromJson(Map<String, dynamic>.from(response));
  }
}
