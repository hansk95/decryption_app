import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/keystore_service.dart';
import '../services/cryptography.dart';
import 'qr_scanner_page.dart';
import 'qr_dialog.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // lokale Kontaktliste (id,name). Du kannst sie später aus persistenter Quelle laden.
  List<Map<String, String>> contacts = [
    {'id': 'max', 'name': 'Max Mustermann'},
    {'id': 'erika', 'name': 'Erika Musterfrau'},
  ];

  String? _ownPublic;

  @override
  void initState() {
    super.initState();
    _loadOwnPublic();
  }

  void _loadOwnPublic() {
    if (KeyStoreService.instance.isUnlocked) {
      setState(() {
        _ownPublic = KeyStoreService.instance.getOwnPublicKeyBase64();
      });
    } else {
      setState(() {
        _ownPublic = null;
      });
    }
  }

  Future<void> _showKeystoreDialog() async {
    if (!KeyStoreService.instance.isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keystore ist gesperrt. Bitte erst einloggen.')),
      );
      return;
    }

    final contactPubs = KeyStoreService.instance.listContactIdsFromKeystore();
    final contactKeys = KeyStoreService.instance.listContactIdsForKeys();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Keystore-Inhalt'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Eigener Public Key:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                SelectableText(_ownPublic ?? 'Nicht vorhanden'),
                const SizedBox(height: 12),
                const Text('Kontakt - Public Keys:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (contactPubs.isEmpty) const Text('Keine Contact-PublicKeys gespeichert.'),
                for (final id in contactPubs) ...[
                  const Divider(),
                  Text('Kontakt: $id', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  SelectableText(KeyStoreService.instance.getContactPublicKey(id) ?? '---'),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Kopieren'),
                        onPressed: () {
                          final txt = KeyStoreService.instance.getContactPublicKey(id) ?? '';
                          Clipboard.setData(ClipboardData(text: txt));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PublicKey kopiert')));
                        },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                const Text('Kontakt - Symmetrische Keys:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (contactKeys.isEmpty) const Text('Keine symmetrischen Kontakt-Keys gespeichert.'),
                for (final id in contactKeys) ...[
                  const Divider(),
                  Text('Kontakt: $id', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  SelectableText(KeyStoreService.instance.getContactKey(id) ?? '---'),
                ],
                const SizedBox(height: 8),
                const Divider(),
                TextButton(
                  onPressed: () {
                    final priv = KeyStoreService.instance.getOwnPrivateKeyBase64();
                    if (priv != null) {
                      Clipboard.setData(ClipboardData(text: priv));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privater Key kopiert (vorsicht!)')));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kein privater Key vorhanden')));
                    }
                  },
                  child: const Text('Privaten Key kopieren (vorsichtig!)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Schließen')),
          ],
        );
      },
    );
  }

  Future<void> _addContactDialog() async {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final pubController = TextEditingController(); // optional PublicKey

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Neuen Kontakt hinzufügen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: idController, decoration: const InputDecoration(labelText: 'ID (kurz)'), autofocus: true),
                const SizedBox(height: 8),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 8),
                TextField(controller: pubController, decoration: const InputDecoration(labelText: 'PublicKey (optional, Base64)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
            ElevatedButton(
              onPressed: () {
                if (idController.text.trim().isEmpty || nameController.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('Hinzufügen'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final id = idController.text.trim();
      final name = nameController.text.trim();
      final pub = pubController.text.trim();
      setState(() {
        contacts.add({'id': id, 'name': name});
      });
      if (pub.isNotEmpty) {
        if (!KeyStoreService.instance.isUnlocked) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keystore gesperrt: PublicKey nicht gespeichert')));
        } else {
          await KeyStoreService.instance.saveContactPublicKey(id, pub);
        }
      }
    }
  }

  Future<void> _onContactTap(Map<String, String> contact) async {
    final contactId = contact['id']!;
    final contactName = contact['name']!;
    String mode = 'Encrypt';
    final inputController = TextEditingController();
    String output = '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateSB) {
          return AlertDialog(
            title: Text('$contactName ($contactId)'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mode Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mode == 'Encrypt' ? Colors.blue : Colors.grey[300],
                          foregroundColor: mode == 'Encrypt' ? Colors.white : Colors.black,
                        ),
                        onPressed: () => setStateSB(() => mode = 'Encrypt'),
                        child: const Text('Encrypt'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mode == 'Decrypt' ? Colors.blue : Colors.grey[300],
                          foregroundColor: mode == 'Decrypt' ? Colors.white : Colors.black,
                        ),
                        onPressed: () => setStateSB(() => mode = 'Decrypt'),
                        child: const Text('Decrypt'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (mode == 'Decrypt')
                    Center(
                      child: FloatingActionButton(
                        heroTag: 'qrScan',
                        mini: true,
                        child: const Icon(Icons.qr_code_scanner),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const QrScannerPage()),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (mode == 'Encrypt') ...[
                    TextField(
                      controller: inputController,
                      decoration: const InputDecoration(labelText: 'Nachricht zum Verschlüsseln'),
                      minLines: 3,
                      maxLines: 6,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final pub = KeyStoreService.instance.getContactPublicKey(contactId);
                        if (pub == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kein PublicKey für Kontakt vorhanden')));
                          return;
                        }
                        try {
                          final payload = await CryptoService.encryptForRecipient(pub, inputController.text);
                          setStateSB(() => output = payload);
                        } catch (e) {
                          setStateSB(() => output = 'Fehler: $e');
                        }
                      },
                      child: const Text('Verschlüsseln'),
                    ),
                  ] else ...[
                    TextField(
                      controller: inputController,
                      decoration: const InputDecoration(labelText: 'Payload zum Entschlüsseln (paste)'),
                      minLines: 3,
                      maxLines: 6,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final priv = KeyStoreService.instance.getOwnPrivateKeyBase64();
                        if (priv == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eigener privater Key fehlt')));
                          return;
                        }
                        try {
                          final plain = await CryptoService.decryptWithPrivate(priv, inputController.text);
                          setStateSB(() => output = plain);
                        } catch (e) {
                          setStateSB(() => output = 'Fehler: $e');
                        }
                      },
                      child: const Text('Entschlüsseln'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (output.isNotEmpty) ...[
                    const Divider(),
                    const Text('Ergebnis:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    SelectableText(output),
                    Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.copy),
                          label: const Text('Kopieren'),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: output));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kopiert')));
                          },
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.qr_code),
                          label: const Text('QR anzeigen'),
                          onPressed: () {
                            final jsonPayload = jsonEncode({
                              'type': 'message',
                              'payload': output,
                            });
                            QrDialog.show(context, jsonPayload, title: 'Verschlüsselte Nachricht');
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Schließen')),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // UI: own public key card + contact list + keystore button + add contact FAB
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontakte'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              onPressed: () {
                // Keystore sperren und zurück zur Login-Seite
                KeyStoreService.instance.lock();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ),
          IconButton(
            tooltip: 'Keystore anzeigen',
            icon: const Icon(Icons.vpn_key),
            onPressed: _showKeystoreDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Mein Public Key'),
                subtitle: SelectableText(_ownPublic ?? 'Keystore gesperrt oder kein Key'),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: _loadOwnPublic,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: contacts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final c = contacts[index];
                  return Card(
                    child: ListTile(
                      title: Text(c['name']!),
                      subtitle: Text('id: ${c['id']}'),
                      onTap: () => _onContactTap(c),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Kontakt löschen',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Kontakt löschen?'),
                              content: Text('Willst du ${c['name']} wirklich löschen?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Abbrechen')),
                                ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Löschen')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            setState(() {
                              contacts.removeAt(index);
                            });
                            if (KeyStoreService.instance.isUnlocked) {
                              await KeyStoreService.instance.deleteContactKey(c['id']!);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Kontakt ${c['name']} gelöscht')),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContactDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}