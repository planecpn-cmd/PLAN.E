import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/core/image_url.dart';

void main() {
  group('resizedImageUrl', () {
    test('rewrites w= on an Unsplash URL', () {
      final result = resizedImageUrl(
        'https://images.unsplash.com/photo-abc?q=80&w=1000',
        width: 400,
      );
      expect(result, 'https://images.unsplash.com/photo-abc?q=80&w=400');
    });

    test('preserves other query params (q=80 stays)', () {
      final result = resizedImageUrl(
        'https://images.unsplash.com/photo-abc?q=80&w=800',
        width: 200,
      );
      final uri = Uri.parse(result);
      expect(uri.queryParameters['q'], '80');
      expect(uri.queryParameters['w'], '200');
    });

    test('non-Unsplash host is passed through completely unchanged', () {
      const url = 'https://supabase.example.com/storage/v1/avatars/user-1.jpg';
      expect(resizedImageUrl(url, width: 400), url);
    });

    test('Unsplash URL with no w= param is passed through unchanged '
        '(never invents a query param the source never had)', () {
      const url = 'https://images.unsplash.com/photo-abc?q=80';
      expect(resizedImageUrl(url, width: 400), url);
    });

    test('an unparseable string is passed through unchanged, not thrown', () {
      const url = 'not a url at all {{{';
      expect(resizedImageUrl(url, width: 400), url);
    });

    test('empty string is passed through unchanged', () {
      expect(resizedImageUrl('', width: 400), '');
    });

    test('a host that merely contains "unsplash" as a substring does not match '
        '(exact host check, not a naive .contains)', () {
      const url = 'https://evil-unsplash.attacker.com/photo?w=1000';
      expect(resizedImageUrl(url, width: 400), url);
    });
  });
}
