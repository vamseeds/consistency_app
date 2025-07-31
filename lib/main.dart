import 'package:consistency_app/screens/login_screen.dart';
import 'package:consistency_app/screens/task_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('jwt_token');
  runApp(ConsistencyApp(initialRoute: token == null ? '/login' : '/tasks'));
}

class ConsistencyApp extends StatelessWidget {
  final String initialRoute;

  const ConsistencyApp({required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consistency Planner',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => LoginScreen(),
        '/tasks': (context) => TaskListScreen(),
      },
    );
  }
}
