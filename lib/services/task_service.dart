import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:consistency_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../utils/utils.dart';

class TaskService {
  static const host="192.168.0.104";
  static const String baseUrl = 'http://$host:8080/api/tasks';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<http.Response> _sendRequest(Future<http.Response> Function() httpCall, String action, BuildContext? context, VoidCallback? onRetry) async {
    try {
      return await httpCall().timeout(const Duration(seconds: 10));
    } on SocketException {
      final error = Exception('Network error: No connection');
      _triggerRetry(error, action, context, onRetry);
      throw error;
    } on TimeoutException {
      final error = Exception('Request timed out');
      _triggerRetry(error, action, context, onRetry);
      throw error;
    }on http.ClientException {
      final error = Exception('Failed to connect to server');
      _triggerRetry(error, action, context, onRetry);
      throw error;
    } catch (e) {
      final error = Exception('Failed to $action: $e');
      _showError(error, context);
      throw error;
    }
  }

  void _showError(Exception error, BuildContext? context) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: ${error.toString()}')),
      );
    }
  }

  void _triggerRetry(Exception error, String action, BuildContext? context, VoidCallback? onRetry) {
    if (context != null && context.mounted && onRetry != null) {
      handleErrorWithRetry(
        context,
        error,
        onRetry,
        errorMessage: 'Failed to $action',
        isMounted: context.mounted,
      );
    }
  }

  void _handleResponse(http.Response response, String action, BuildContext? context, VoidCallback? onRetry) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return; // Success
    } else if (response.statusCode == 401) {
      if (context != null && context.mounted) {
        SharedPreferences.getInstance().then((prefs) {
          prefs.remove('jwt_token');
          print('JWT token cleared due to 401');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please log in again.')),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        });
      }
      throw Exception('Unauthorized: ${response.statusCode}');
    } else if (response.statusCode == 403) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied')),
        );
      }
      throw Exception('Forbidden: ${response.statusCode}');
    } else {
      final error = Exception('Failed to $action: ${response.statusCode}');
      _triggerRetry(error, action, context, onRetry);
      throw error;
    }
  }

  Future<List<Task>> fetchTasks({BuildContext? context, VoidCallback? onRetry}) async {
    final token = await _getToken();
    final response = await _sendRequest(
      () => http.get(
        Uri.parse(baseUrl),
        headers: {'Authorization': 'Bearer $token'},
      ),
      'fetch tasks',
      context,
      onRetry,
    );
    _handleResponse(response, 'fetch tasks', context, onRetry);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Task.fromJson(json)).toList();
  }

  Future<Task> createTask(Task task, {BuildContext? context, VoidCallback? onRetry}) async {
    final token = await _getToken();
    final response = await _sendRequest(
      () => http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(task.toJson()),
      ),
      'create task',
      context,
      onRetry,
    );
    _handleResponse(response, 'create task', context, onRetry);
    return Task.fromJson(jsonDecode(response.body));
  }

  Future<Task> updateTask(Task task, {BuildContext? context, VoidCallback? onRetry}) async {
    final token = await _getToken();
    final response = await _sendRequest(
      () => http.put(
        Uri.parse('$baseUrl/${task.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(task.toJson()),
      ),
      'update task',
      context,
      onRetry,
    );
    _handleResponse(response, 'update task', context, onRetry);
    return Task.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteTask(String id, {BuildContext? context, VoidCallback? onRetry}) async {
    final token = await _getToken();
    final response = await _sendRequest(
      () => http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {'Authorization': 'Bearer $token'},
      ),
      'delete task',
      context,
      onRetry,
    );
    _handleResponse(response, 'delete task', context, onRetry);
  }

  Future<Task> toggleTask(String id, bool completed, {BuildContext? context, VoidCallback? onRetry}) async {
    final token = await _getToken();
    final response = await _sendRequest(
      () => http.patch(
        Uri.parse('$baseUrl/$id/toggle'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'completed': completed}),
      ),
      'toggle task',
      context,
      onRetry,
    );
    _handleResponse(response, 'toggle task', context, onRetry);
    return Task.fromJson(jsonDecode(response.body));
  }

  Future<String> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('http://$host:8080/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    print('Login Response: ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      final token = jsonDecode(response.body)['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      return token;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }
}
