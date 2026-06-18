import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

class DistriGolfApp extends StatefulWidget {
  const DistriGolfApp({super.key});

  @override
  State<DistriGolfApp> createState() => _DistriGolfAppState();
}

class _DistriGolfAppState extends State<DistriGolfApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().tryAutoLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'DistriGolf Preventa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
    );
  }
}
