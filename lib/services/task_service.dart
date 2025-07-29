import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/task.dart';

class TaskService {
  final String baseUrl = 'http://localhost:8080/api/tasks';

  Future<List<Task>> fetchTasks() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);

      return jsonList.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tasks');
    }
  }
}
