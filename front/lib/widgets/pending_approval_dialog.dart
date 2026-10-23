
import 'package:flutter/material.dart';

class PendingApprovalDialog {
  PendingApprovalDialog._();

  static Future<void> show(
    BuildContext context, {
    String message = 'Your account is awaiting approval.',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.hourglass_top_rounded,
            size: 44,
            color: Color(0xFFB7791F),
          ),
          title: const Text(
            'Approval pending',
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}
