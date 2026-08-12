// Phase 3 of docs/OFFLINE_CACHE_PLAN.md: home rails, categories, and regions
// now go through OfflineCache. Verifies the cache-aside contract from §2.3
// against a connection guaranteed to fail — a cached value is returned
// instead of the network error, and a cold cache still rethrows exactly as
// before (no regression for a user who's never loaded this data).
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/core/offline_cache.dart';
import 'package:plan_e/models/category.dart';
import 'package:plan_e/models/region.dart';
import 'package:plan_e/repositories/experience_repository.dart';
import 'package:plan_e/repositories/taxonomy_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Port 1 refuses connections immediately — deterministic, fast failure.
// Constructed fresh inside each test, not at file/main() scope — the HTTP
// mock TestWidgetsFlutterBinding installs only applies inside a running
// test's zone, and SupabaseClient's constructor builds its http.Client
// eagerly.
SupabaseClient unreachableClient() =>
    SupabaseClient('http://127.0.0.1:1', 'test-key');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TaxonomyRepository.getCategories', () {
    test('network fails, cache has data → returns the cached categories', () async {
      final now = DateTime.utc(2026, 1, 1);
      await OfflineCache.write('categories', [
        Category(id: 'c1', slug: 'trekking', nameEn: 'Trekking', nameNe: 'ट्रेकिङ', createdAt: now).toJson(),
      ]);

      final repo = TaxonomyRepository(unreachableClient());
      final categories = await repo.getCategories();

      expect(categories, hasLength(1));
      expect(categories.first.slug, 'trekking');
    });

    test('network fails, no cache → rethrows (no regression for a cold cache)', () async {
      final repo = TaxonomyRepository(unreachableClient());
      expect(() => repo.getCategories(), throwsA(anything));
    });
  });

  group('TaxonomyRepository.getRegions', () {
    test('network fails, cache has data → returns the cached regions', () async {
      final now = DateTime.utc(2026, 1, 1);
      await OfflineCache.write('regions', [
        Region(id: 'r1', slug: 'everest', nameEn: 'Everest Region', nameNe: 'सगरमाथा', createdAt: now).toJson(),
      ]);

      final repo = TaxonomyRepository(unreachableClient());
      final regions = await repo.getRegions();

      expect(regions, hasLength(1));
      expect(regions.first.slug, 'everest');
    });

    test('network fails, no cache → rethrows', () async {
      final repo = TaxonomyRepository(unreachableClient());
      expect(() => repo.getRegions(), throwsA(anything));
    });
  });

  group('ExperienceRepository.getHomeRails', () {
    test('network fails, cache has data → returns the cached rails map', () async {
      final now = DateTime.utc(2026, 1, 1);
      final experienceJson = {
        'id': 'exp-1',
        'title': 'Everest Base Camp Trek',
        'slug': 'ebc-trek',
        'cover_image_url': 'https://example.com/x.jpg',
        'price_paisa': 500000,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      await OfflineCache.write('home_rails', {
        'recommended': [experienceJson],
        'trending': [experienceJson],
      });

      final repo = ExperienceRepository(unreachableClient());
      final rails = await repo.getHomeRails();

      expect(rails['recommended'], hasLength(1));
      expect(rails['recommended']!.first.title, 'Everest Base Camp Trek');
      expect(rails['trending'], hasLength(1));
    });

    test('network fails, no cache → rethrows', () async {
      final repo = ExperienceRepository(unreachableClient());
      expect(() => repo.getHomeRails(), throwsA(anything));
    });
  });
}
