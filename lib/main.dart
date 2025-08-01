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

  ConsistencyApp({required this.initialRoute});

  @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'Consistency Planner',
            theme: ThemeData(
                primarySwatch: Colors.teal, // Custom primary color
                colorScheme: ColorScheme.fromSwatch(
                    primarySwatch: Colors.teal,
                    accentColor: Colors.amber, // For buttons, FAB
                    backgroundColor: Colors.grey[100], // Light background
                ),
                scaffoldBackgroundColor: Colors.grey[100],
                appBarTheme: const AppBarTheme(
                    elevation: 4,
                    titleTextStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                    ),
                    iconTheme: IconThemeData(color: Colors.teal),
                ),
                textTheme: const TextTheme(
                    bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
                    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                ),
                floatingActionButtonTheme: const FloatingActionButtonThemeData(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                ),
                cardTheme: CardThemeData( // Fixed: Use CardThemeData
                    elevation: 4, // Supported in 3.24, check for deprecation
                    shadowColor: Colors.grey.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                    ),
                    surfaceTintColor: Colors.white, // White background
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                ),
            ),
            initialRoute: initialRoute,
            routes: {
                '/login': (context) => LoginScreen(),
                '/tasks': (context) => TaskListScreen(),
            },
        );
    }
}
