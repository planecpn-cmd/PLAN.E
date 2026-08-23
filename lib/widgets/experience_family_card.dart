import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/image_cache_manager.dart';
import '../core/image_url.dart';
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
        placeholder: (_, __) => const ColoredBox(color: AppColors.sage),
        errorWidget: (_, __, ___) => _assetFallback(),
      );
    }
    return _assetFallback();
  }

  Widget _assetFallback() {
    if (family.slug == 'adventure-together') {
      return Image.asset(
        'assets/images/explore_header_mountains.png',
        fit: BoxFit.cover,
        alignment: Alignment.center,
      );
    }

    final (scale, alignment) = switch (family.slug) {
      'trips-tours' => (1.8, const Alignment(0.75, -0.72)),
      'live-like-a-local' => (1.85, const Alignment(0.82, 0.75)),
      'mind-soul' => (2.15, const Alignment(-0.08, 0.68)),
      'meet-people' => (1.9, const Alignment(0.95, 0.72)),
      'give-back' => (2.0, const Alignment(-0.88, 0.72)),
      _ => (1.0, Alignment.center),
    };

    return ClipRect(
      child: Transform.scale(
        scale: scale,
        alignment: alignment,
        child: Image.asset(
          'assets/images/home_experiences_hero.png',
          fit: BoxFit.cover,
          alignment: alignment,
        ),
      ),
    );
  }
}
