import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const TeamioApp());
}

class TeamioApp extends StatelessWidget {
  const TeamioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Teamio',
      theme: ThemeData.dark(),
      home: const SplashScreen(), // <--- App starts here now
    );
  }
}