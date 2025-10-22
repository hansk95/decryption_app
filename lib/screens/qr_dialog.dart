import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class QrDialog {
  static Future<void> show(BuildContext context, String payload, {String title = 'QR'}) {
    return showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Wichtiger Fix: Dialog passt sich Inhalt an
            children: [
              SizedBox(
                width: 280,
                height: 280,
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(payload),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: payload));
                Navigator.of(context).pop();
              },
              child: const Text('Kopieren'),
            ),
            TextButton(
              onPressed: () {
                Share.share(payload);
                Navigator.of(context).pop();
              },
              child: const Text('Teilen'),
            ),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Schließen')),
          ],
        );
      },
    );
  }
}