import 'package:flutter/material.dart';
import 'auth/login_page.dart';
import 'auth/register_page.dart';
import 'home_page_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/homepage', // Set initial screen to HomePageWidget
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/homepage': (context) => const HomePageWidget(),
      },
    );
  }
}
