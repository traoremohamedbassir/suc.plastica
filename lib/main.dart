import 'package:firebase_core/firebase_core.dart';
import 'package:plastica_suc/connection/login.dart';
import 'package:plastica_suc/firebase_options.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApp();
  }

  Future<void> _loadApp() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _isLoading
          ? Scaffold(
              backgroundColor: const Color(0xFFF5F7FB),
              body: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Plastica Suc",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: Colors.yellow,
                          fontStyle: FontStyle.italic,
                          
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Chargement...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const Login(),
    );
  }
}