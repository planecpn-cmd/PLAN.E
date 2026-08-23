import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/core/push_notification_service.dart';

void main() {
  test('accepts only booking-scoped chat notification routes', () {
    expect(
      PushNotificationService.isSafeTripMessageRoute(
        '/chat/95000000-0000-0000-0000-000000000008',
      ),
      isTrue,
    );
    expect(
      PushNotificationService.isSafeTripMessageRoute(
        '/host/messages/95000000-0000-0000-0000-000000000008',
      ),
      isTrue,
    );
    expect(PushNotificationService.isSafeTripMessageRoute('/profile'), isFalse);
    expect(
      PushNotificationService.isSafeTripMessageRoute(
        '/chat/not-a-booking?redirect=https://evil.example',
      ),
      isFalse,
    );
  });
}
