import 'package:consistency_app/screens/login_screen.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(const ConsistencyApp());
}

class ConsistencyApp extends StatelessWidget {
  const ConsistencyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consistency App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}

