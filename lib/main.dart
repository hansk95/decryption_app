import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sliding_action_button/sliding_action_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '(D)Encrypt',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      //home: const MyHomePage(title: 'Test Flutter App'),
      home: const LoginPage(),
    );
  }
}

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
  void _login() async {
    String password = _passwordController.text;
    String? savedPassword = await _getSavedPassword();

    // Einfaches Beispiel: Passwort checken
    if (savedPassword == null) {
      // Erstmaliges Setzen des Passworts
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte registriere dich zuerst!')),
      );
      return;
    }
    if (password == savedPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falsches Passwort!')),
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
              color: Colors.white.withOpacity(0.85), // Optional: halbtransparenter Hintergrund
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '(D)Encrypt',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
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
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white
                    ),
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white
                    ),
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

class Contact {
  final String name;
  final String contactKey;

  Contact(this.name, this.contactKey);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Contact> contacts = [
    Contact('Hans Kuntsche', '12345'),
    Contact('Paul Weibbrecht', '56789'),
  ];

  void _addContact() async {
    final nameController = TextEditingController();
    final keyController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Neuen Kontakt hinzufügen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyController,
                decoration: const InputDecoration(labelText: 'Key'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty &&
                    keyController.text.trim().isNotEmpty) {
                  Navigator.pop(context, {
                    'name': nameController.text.trim(),
                    'key': keyController.text.trim(),
                  });
                }
              },
              child: const Text('Hinzufügen'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        contacts.add(Contact(result['name']!, result['key']!));
      });
    }
  }

  void _deleteContact(int index) {
    setState(() {
      contacts.removeAt(index);
    });
  }

  void _showContactDialog(Contact contact) {
    double sliderValue = 0;
    final textController = TextEditingController();
    String modeText = 'Encrypt';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(''),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Encrypt'),
                      Expanded(
                        child: Slider(
                          value: sliderValue,
                          min: 0,
                          max: 1,
                          divisions: 1,
                          label: modeText,
                          onChanged: (value) {
                            setState(() {
                              sliderValue = value;
                              modeText = value == 0 ? 'Encrypt' : 'Decrypt';
                            });
                          },
                        ),
                      ),
                      const Text('Decrypt'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      labelText: 'Gib deine Nachricht ein',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 3,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Convert'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Kontakte',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold, 
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: contacts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(contact.name),
              subtitle: Text('Key: ${contact.contactKey}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Löschen',
                onPressed: () => _deleteContact(index),
              ),
              onTap: () => _showContactDialog(contact),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        tooltip: 'Kontakt hinzufügen',
        child: const Icon(Icons.add),
      ),
    );
  }
}
