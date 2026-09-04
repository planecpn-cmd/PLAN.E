import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/image_cache_manager.dart';
import '../core/image_url.dart';
import '../core/photo_alignment.dart';
import '../models/experience_family.dart';
import '../theme/theme.dart';

class ExperienceFamilyCard extends StatelessWidget {
  final ExperienceFamily family;
  final VoidCallback onTap;

  const ExperienceFamilyCard({
    super.key,
    required this.family,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${family.nameEn}. ${family.description}',
      child: Material(
        color: AppColors.deep,
        borderRadius: AppRadii.borderMd16,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _FamilyImage(family: family),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x16000000), Color(0xD9001B14)],
                    stops: [0.2, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      family.nameEn,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontFamily: 'serif',
                        fontSize: 17,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _compactSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.sage,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _compactSubtitle => switch (family.slug) {
    'trips-tours' => 'Tours, trips & packages',
    'adventure-together' => 'Shared outdoor challenges',
    'live-like-a-local' => 'Food, culture & homestays',
    'mind-soul' => 'Wellness & creative escapes',
    'meet-people' => 'Activities, events & community',
    'give-back' => 'Volunteering & local impact',
    _ => family.description,
  };
}

class _FamilyImage extends StatelessWidget {
  final ExperienceFamily family;

  const _FamilyImage({required this.family});

  @override
  Widget build(BuildContext context) {
    final imageUrl = family.coverImageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: resizedImageUrl(imageUrl, width: 500),
        cacheManager: AppImageCacheManager.instance,
        fit: BoxFit.cover,
        alignment: photoAlignment(imageUrl),
        placeholder: (_, __) => const ColoredBox(color: AppColors.sage),
        errorWidget: (_, __, ___) => _assetFallback(),
      );
    }
    return _assetFallback();
  }

  Widget _assetFallback() => const ColoredBox(color: AppColors.sage);
}
