import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/login_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AppP4(),
    ),
  );
}

class AppP4 extends StatelessWidget {
  const AppP4({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CEET – Asistencia P4',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D4FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}
