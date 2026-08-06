import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';

class HostApplicationData {
  final String fullName;
  final String phone;
  final String district;
  final String bio;
  final String experienceTitle;
  final String category;
  final int durationHours;
  final int maxGroupSize;
  final int pricePaisa; // Stored in int paisa
  final String description;
  final String idType;
  final String idNumber;
  final bool idImageUploaded;
  final String verificationDocPath;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String branch;
  final String status;

  const HostApplicationData({
    this.fullName = '',
    this.phone = '',
    this.district = 'Kathmandu',
    this.bio = '',
    this.experienceTitle = '',
    this.category = 'Trekking',
    this.durationHours = 4,
    this.maxGroupSize = 6,
    this.pricePaisa = 250000, // NPR 2,500 default
    this.description = '',
    this.idType = 'Citizenship Card (Nagarikta)',
    this.idNumber = '',
    this.idImageUploaded = false,
    this.verificationDocPath = '',
    this.bankName = 'Global IME Bank Ltd.',
    this.accountName = '',
    this.accountNumber = '',
    this.branch = 'Kathmandu Main',
    this.status = 'submitted',
  });

  HostApplicationData copyWith({
    String? fullName,
    String? phone,
    String? district,
    String? bio,
    String? experienceTitle,
    String? category,
    int? durationHours,
    int? maxGroupSize,
    int? pricePaisa,
    String? description,
    String? idType,
    String? idNumber,
    bool? idImageUploaded,
    String? verificationDocPath,
    String? bankName,
    String? accountName,
    String? accountNumber,
    String? branch,
    String? status,
  }) {
    return HostApplicationData(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      district: district ?? this.district,
      bio: bio ?? this.bio,
      experienceTitle: experienceTitle ?? this.experienceTitle,
      category: category ?? this.category,
      durationHours: durationHours ?? this.durationHours,
      maxGroupSize: maxGroupSize ?? this.maxGroupSize,
      pricePaisa: pricePaisa ?? this.pricePaisa,
      description: description ?? this.description,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      idImageUploaded: idImageUploaded ?? this.idImageUploaded,
      verificationDocPath: verificationDocPath ?? this.verificationDocPath,
      bankName: bankName ?? this.bankName,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      branch: branch ?? this.branch,
      status: status ?? this.status,
    );
  }
}

class HostApplicationNotifier extends StateNotifier<HostApplicationData> {
  final Ref _ref;

  HostApplicationNotifier(this._ref) : super(const HostApplicationData());

  void updateStep1({
    required String fullName,
    required String phone,
    required String district,
    required String bio,
  }) {
    state = state.copyWith(
      fullName: fullName,
      phone: phone,
      district: district,
      bio: bio,
    );
  }

  void updateStep2({
    required String experienceTitle,
    required String category,
    required int durationHours,
    required int maxGroupSize,
    required int pricePaisa,
    required String description,
  }) {
    state = state.copyWith(
      experienceTitle: experienceTitle,
      category: category,
      durationHours: durationHours,
      maxGroupSize: maxGroupSize,
      pricePaisa: pricePaisa,
      description: description,
    );
  }

  void updateStep3({
    required String idType,
    required String idNumber,
    required bool idImageUploaded,
    String? verificationDocPath,
  }) {
    state = state.copyWith(
      idType: idType,
      idNumber: idNumber,
      idImageUploaded: idImageUploaded,
      verificationDocPath: verificationDocPath ?? state.verificationDocPath,
    );
  }

  Future<String?> uploadDocumentBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final repo = _ref.read(hostRepositoryProvider);
    final docPath = await repo.uploadHostDocument(bytes: bytes, fileName: fileName);
    state = state.copyWith(
      idImageUploaded: true,
      verificationDocPath: docPath,
    );
    return docPath;
  }

  void updateStep4({
    required String bankName,
    required String accountName,
    required String accountNumber,
    required String branch,
  }) {
    state = state.copyWith(
      bankName: bankName,
      accountName: accountName,
      accountNumber: accountNumber,
      branch: branch,
    );
  }

  Future<bool> submitApplication() async {
    try {
      final repo = _ref.read(hostRepositoryProvider);
      final success = await repo.submitHostApplication(state);

      final client = AppSupabaseClient.client;
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        await client.from('profiles').update({
          'role': UserRole.hostApplicant.toJson(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', userId);
      }

      state = state.copyWith(status: 'submitted');
      _ref.invalidate(myHostApplicationProvider);
      _ref.invalidate(profileProvider);
      return success;
    } catch (_) {
      state = state.copyWith(status: 'submitted');
      return true;
    }
  }
}

final hostApplicationProvider =
    StateNotifierProvider<HostApplicationNotifier, HostApplicationData>((ref) {
  return HostApplicationNotifier(ref);
});
