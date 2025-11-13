import 'package:flutter/material.dart';
import 'landingpage/landing_page1.dart';
import 'entry/login.dart';
import 'home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SPARE-M',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LandingPage(), // ✅ ganti halaman awal di sini
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
