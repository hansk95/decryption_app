import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/keystore_service.dart';
import '../services/cryptography.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _passwordController = TextEditingController();

  Future<String?> _getSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_password');
  }

  Future<void> _savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_password', password);
  }

  Future<void> _ensureOwnKeypair() async {
    if (KeyStoreService.instance.getOwnPrivateKeyBase64() == null) {
      final pair = await CryptoService.generateX25519KeypairBase64();
      await KeyStoreService.instance.saveOwnKeypairBase64(pair['private']!, pair['public']!);
    }
  }

  void _login() async {
    String password = _passwordController.text;
    String? savedPassword = await _getSavedPassword();

    if (savedPassword == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte registriere dich zuerst!')),
      );
      return;
    }

    if (password == savedPassword) {
      try {
        await KeyStoreService.instance.unlock(); // Keystore entsperren
        await _ensureOwnKeypair(); // eigenes Schlüsselpaar erzeugen falls nötig
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Keystore unlock failed: $e')),
        );
        return;
      }
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falsches Passwort')),
      );
    }
  }

  void _showRegisterDialog() async {
    final pwController = TextEditingController();
    final confirmController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrieren'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pwController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Passwort wählen'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Passwort bestätigen'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (pwController.text.isNotEmpty &&
                    pwController.text == confirmController.text) {
                  await _savePassword(pwController.text);
                  // Keystore entsperren und eigenes Keypair erzeugen und speichern
                  try {
                    await KeyStoreService.instance.unlock();
                    await _ensureOwnKeypair();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Fehler beim Initialisieren des Keystores: $e')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Registrierung erfolgreich!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwörter stimmen nicht überein!')),
                  );
                }
              },
              child: const Text('Registrieren'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/login_bg.jpg',
            fit: BoxFit.cover,
          ),
          Center(
            child: Container(
              color: Colors.white.withOpacity(0.85),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '(D)Encrypt',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Passwort',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    onPressed: _showRegisterDialog,
                    child: const Text('Registrieren'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}