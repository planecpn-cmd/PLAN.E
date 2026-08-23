import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class SelectedTripAttachment {
  const SelectedTripAttachment({
    required this.bytes,
    required this.fileName,
    this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String? mimeType;
}

class TripAttachmentPicker {
  const TripAttachmentPicker._();

  static Future<SelectedTripAttachment?> pickPhoto(ImageSource source) async {
    final photo = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2400,
      imageQuality: 88,
      requestFullMetadata: false,
    );
    if (photo == null) return null;
    if (await photo.length() > 10 * 1024 * 1024) {
      throw ArgumentError('Attachment must be 10 MB or smaller.');
    }
    return SelectedTripAttachment(
      bytes: await photo.readAsBytes(),
      fileName: photo.name,
      mimeType: photo.mimeType,
    );
  }

  static Future<SelectedTripAttachment?> pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    if (file.size < 1 || file.size > 10 * 1024 * 1024) {
      throw ArgumentError('Attachment must be between 1 byte and 10 MB.');
    }
    final bytes = file.bytes;
    if (bytes == null) {
      throw StateError('Could not read the selected attachment.');
    }
    return SelectedTripAttachment(bytes: bytes, fileName: file.name);
  }
}
