import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/trip_tools_providers.dart';
import '../theme/theme.dart';

/// Renders a private attachment through a short-lived signed URL. The storage
/// path itself is never exposed as a public URL.
class PrivateTripAttachment extends ConsumerStatefulWidget {
  const PrivateTripAttachment({super.key, required this.storagePath});

  final String storagePath;

  @override
  ConsumerState<PrivateTripAttachment> createState() =>
      _PrivateTripAttachmentState();
}

class _PrivateTripAttachmentState extends ConsumerState<PrivateTripAttachment> {
  late Future<String> _signedUrl;

  @override
  void initState() {
    super.initState();
    _signedUrl = _createSignedUrl();
  }

  @override
  void didUpdateWidget(covariant PrivateTripAttachment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storagePath != widget.storagePath) {
      _signedUrl = _createSignedUrl();
    }
  }

  Future<String> _createSignedUrl() => ref
      .read(tripChatRepositoryProvider)
      .createAttachmentSignedUrl(widget.storagePath);

  bool get _isPdf => widget.storagePath.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _signedUrl,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const SizedBox(
          width: 150,
          height: 90,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      final url = snapshot.data;
      if (url == null) {
        return const _AttachmentUnavailable();
      }
      if (_isPdf) {
        return InkWell(
          onTap: () =>
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.picture_as_pdf_outlined),
                SizedBox(width: 8),
                Text('Open PDF'),
              ],
            ),
          ),
        );
      }
      return ClipRRect(
        borderRadius: AppRadii.borderSm8,
        child: Image.network(
          url,
          width: 220,
          height: 150,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const _AttachmentUnavailable(),
        ),
      );
    },
  );
}

class _AttachmentUnavailable extends StatelessWidget {
  const _AttachmentUnavailable();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.broken_image_outlined, size: 18),
        SizedBox(width: 6),
        Text('Attachment unavailable'),
      ],
    ),
  );
}
