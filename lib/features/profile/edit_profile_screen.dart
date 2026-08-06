// RM-16 Edit Profile Screen
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _bioController;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  Uint8List? _selectedAvatarBytes;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _bioController = TextEditingController();
  }

  void _populateControllers(Profile? profile) {
    if (_initialized) return;
    _nameController.text = profile?.fullName ?? 'Pema Sherpa';
    _phoneController.text = profile?.phone ?? '+977 9841234567';
    _locationController.text = profile?.location ?? 'Kathmandu, Nepal';
    _bioController.text =
        profile?.bio ??
        'Passionate mountain trekker & eco-tourism enthusiast exploring hidden trails across the Himalayas.';
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        bio: _bioController.text.trim(),
      );
      ref.invalidate(profileProvider);

      if (mounted) {
        AppToast.show(
          context,
          message: 'Profile updated successfully!',
          variant: AppToastVariant.success,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Failed to update profile. Please try again.',
          variant: AppToastVariant.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickProfilePhoto() async {
    if (_isUploadingPhoto) return;
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (image == null || !mounted) return;

      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedAvatarBytes = bytes;
        _isUploadingPhoto = true;
      });

      final extension = image.name.contains('.')
          ? image.name.split('.').last.toLowerCase()
          : 'jpg';
      await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(bytes: bytes, extension: extension);
      ref.invalidate(profileProvider);
      if (mounted) {
        AppToast.show(
          context,
          message: 'Profile photo updated!',
          variant: AppToastVariant.success,
        );
      }
    } catch (error) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Unable to update photo. Please try another image.',
          variant: AppToastVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
        ),
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          constraints: AppTouchTarget.minConstraints,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AsyncValueView<Profile?>(
        value: profileAsync,
        onRetry: () => ref.refresh(profileProvider),
        data: (profile) {
          _populateControllers(profile);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Avatar Section
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.forest,
                          backgroundImage: _selectedAvatarBytes != null
                              ? MemoryImage(_selectedAvatarBytes!)
                              : profile?.avatarUrl != null
                              ? NetworkImage(profile!.avatarUrl!)
                              : null,
                          child:
                              _selectedAvatarBytes == null &&
                                  profile?.avatarUrl == null
                              ? Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text[0].toUpperCase()
                                      : 'P',
                                  style: AppTypography.displayMedium.copyWith(
                                    color: AppColors.ivory,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickProfilePhoto,
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.sm8),
                              decoration: const BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                              ),
                              child: _isUploadingPhoto
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: AppColors.white,
                                      size: 18,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl24),

                  // Form Fields inside AppCard
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Full name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg16),
                        AppTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: '+977 98XXXXXXXX',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          keyboardType: TextInputType.phone,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg16),
                        AppTextField(
                          controller: _locationController,
                          label: 'Location / City',
                          hint: 'e.g. Kathmandu, Nepal',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                        const SizedBox(height: AppSpacing.lg16),
                        AppTextField(
                          controller: _bioController,
                          label: 'Bio',
                          hint: 'Tell fellow travelers about yourself...',
                          prefixIcon: const Icon(Icons.notes),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl24),

                  // Save Action Button
                  AppButton(
                    label: 'Save Changes',
                    isFullWidth: true,
                    isLoading: _isSaving,
                    onPressed: _saveProfile,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
