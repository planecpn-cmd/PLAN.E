import 'package:url_launcher/url_launcher.dart';

/// Thin wrappers around url_launcher for opening native OS apps
/// (maps, dialer, mail client) from a device-driven Uri.
class NativeIntents {
  const NativeIntents._();

  static Future<bool> openDirections({
    required double lat,
    required double lng,
    String? label,
  }) async {
    final query = label != null ? '$lat,$lng($label)' : '$lat,$lng';
    final geoUri = Uri.parse('geo:$lat,$lng?q=$query');
    if (await canLaunchUrl(geoUri)) {
      return launchUrl(geoUri, mode: LaunchMode.externalApplication);
    }
    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    return launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> call(String phoneNumber) {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    return launchUrl(uri);
  }

  static Future<bool> emailSupport({
    required String to,
    String? subject,
    String? body,
  }) {
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
      },
    );
    return launchUrl(uri);
  }
}
