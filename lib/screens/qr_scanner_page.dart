import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/keystore_service.dart';
import '../services/cryptography.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Scanner')),
      body: MobileScanner(
        onDetect: (capture) async {
          if (_handled) return;
          _handled = true;

          final barcode = capture.barcodes.first;
          final raw = barcode.rawValue ?? '';

          try {
            final obj = jsonDecode(raw);
            final type = obj['type'] as String?;
            if (type == 'contact') {
              final id = obj['id'] as String? ?? '';
              final name = obj['name'] as String? ?? '';
              final pub = obj['pub'] as String?;
              if (pub != null && KeyStoreService.instance.isUnlocked) {
                await KeyStoreService.instance.saveContactPublicKey(id, pub);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact PublicKey gespeichert')),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Keystore gesperrt oder ungültiger QR')),
                  );
                }
              }
            } else if (type == 'message') {
              final payload = obj['payload'];
              final payloadJson = payload is String ? payload : jsonEncode(payload);
              final priv = KeyStoreService.instance.getOwnPrivateKeyBase64();
              if (priv == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kein privater Key vorhanden')),
                  );
                }
              } else {
                try {
                  final plain = await CryptoService.decryptWithPrivate(priv, payloadJson);
                  if (mounted) {
                    await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Entschlüsselt'),
                        content: SelectableText(plain),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          )
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Entschlüsselung fehlgeschlagen: $e')),
                    );
                  }
                }
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unbekannter QR-Typ')),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kein gültiger JSON-QR')),
              );
            }
          } finally {
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}