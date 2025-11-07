import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'services/keystore_service.dart';

// async main to initialize KeyStoreService before runApp
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  // Initialisiere den KeyStoreService vor dem Start der App
  await KeyStoreService.instance.init();
  // Starte die App
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ncrypt',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}