import 'package:flutter/material.dart';
import 'landingpage/landing_page1.dart';
import 'entry/login.dart';
import '../chat/chat.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'product_detail.dart'; 
import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

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
      home: const LandingPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/chat': (context) => const ChatPage(),
        '/product-detail': (context) {
        final int productId = ModalRoute.of(context)!.settings.arguments as int;
        return ProductDetailPage(productId: productId);
        },
      },
    );
  }
}
