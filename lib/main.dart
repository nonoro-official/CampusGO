import 'package:flutter/material.dart';
import 'pages/splash/splash_screen.dart';

void main() {
  runApp(const FoodikaApp());
}

class FoodikaApp extends StatelessWidget {
  const FoodikaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Foodika",
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F1EA),
        primaryColor: const Color(0xFFE46A3E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE46A3E),
          primary: const Color(0xFFE46A3E),
          secondary: const Color(0xFF2E7D32),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE46A3E),
          foregroundColor: Colors.white,
        ),
      ),
      home: SplashScreen(),
    );
  }
}