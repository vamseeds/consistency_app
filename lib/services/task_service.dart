import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/task.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';

class TaskService {
  final String baseUrl = 'http://localhost:8080/api/tasks';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<List<Task>> fetchTasks() async {
    try {
      final token = await _getToken();
      final response = await http
          .get(
            Uri.parse(baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));
      print('GET Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Task.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied: Insufficient permissions');
      } else {
        throw Exception(
          'Failed to load tasks: ${response.statusCode} ${response.body}',
        );
      }
    } on SocketException {
      throw Exception('Network error: Please check your internet connection');
    } on TimeoutException {
      throw Exception('Request timed out: Server not responding');
    }
  }

  Future<Task> createTask(Task task) async {
    try {
      final token = await _getToken();
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(task.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      print('POST Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Task.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied: Insufficient permissions');
      } else {
        throw Exception(
          'Failed to create task: ${response.statusCode} ${response.body}',
        );
      }
    } on SocketException {
      throw Exception('Network error: Please check your internet connection');
    } on TimeoutException {
      throw Exception('Request timed out: Server not responding');
    }
  }

  Future<Task> toggleTask(String id, bool isCompleted) async {
    try {
      final token = await _getToken();
      final response = await http
          .patch(
            Uri.parse('$baseUrl/$id'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'completed': isCompleted}),
          )
          .timeout(const Duration(seconds: 10));
      print('PATCH Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Task.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied: Insufficient permissions');
      } else {
        throw Exception(
          'Failed to toggle task: ${response.statusCode} ${response.body}',
        );
      }
    } on SocketException {
      throw Exception('Network error: Please check your internet connection');
    } on TimeoutException {
      throw Exception('Request timed out: Server not responding');
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      final token = await _getToken();
      final response = await http
          .delete(
            Uri.parse('$baseUrl/$id'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      print('DELETE Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 204) {
        // Task deleted successfully, no content returned
        print('Task deleted successfully');
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied: Insufficient permissions');
      } else {
        throw Exception(
          'Failed to delete task: ${response.statusCode} ${response.body}',
        );
      }
    } on SocketException {
      throw Exception('Network error: Please check your internet connection');
    } on TimeoutException {
      throw Exception('Request timed out: Server not responding');
    }
  }

  Future<Task> updateTask(Task task) async {
    try {
      final token = await _getToken();
      final response = await http
          .put(
            Uri.parse('$baseUrl/${task.id}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(task.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      print('PUT Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Task.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied: Insufficient permissions');
      } else {
        throw Exception(
          'Failed to update task: ${response.statusCode} ${response.body}',
        );
      }
    } on SocketException {
      throw Exception('Network error: Please check your internet connection');
    } on TimeoutException {
      throw Exception('Request timed out: Server not responding');
    }
  }

  Future<String> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('http://localhost:8080/api/auth/login'),
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
