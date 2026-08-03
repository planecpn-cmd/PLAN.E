// RM-25 Delete Draft Confirmation Dialog
import 'package:flutter/material.dart';

class DeleteDraftDialog extends StatelessWidget {
  const DeleteDraftDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('RM-25 Delete Draft'),
      content: const Text('Are you sure you want to delete this trip draft?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
