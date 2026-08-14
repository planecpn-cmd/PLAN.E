import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/features/auth/auth_repository.dart';

void main() {
  test('SMTP delivery failures are not exposed as raw provider exceptions', () {
    final message = friendlyAuthError(
      StateError('unexpected_failure: Error sending confirmation email'),
    );

    expect(message, contains('verification email'));
    expect(message, isNot(contains('unexpected_failure')));
  });

  test('invalid credentials have a concise message', () {
    expect(
      friendlyAuthError(StateError('Invalid login credentials')),
      'Invalid email or password. Please try again.',
    );
  });

  test('network failures do not expose socket details or backend addresses', () {
    final message = friendlyAuthError(
      Exception(
        'ClientException with SocketException: Connection refused, '
        'address = 192.168.59.61, uri=http://192.168.59.61:54341/auth/v1/recover',
      ),
    );

    expect(message, contains('connect to the server'));
    expect(message, isNot(contains('SocketException')));
    expect(message, isNot(contains('192.168.59.61')));
  });
}
