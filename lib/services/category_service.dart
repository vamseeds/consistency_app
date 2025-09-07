import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';

class CategoryService {
  static const host="192.168.0.104";
  static const String baseUrl = 'http://$host:8080/api/categories';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<List<Category>> fetchCategories() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch categories: ${response.statusCode}');
    }
  }

  Future<Category> createCategory(Category category) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(category.toJson()),
    );
    if (response.statusCode == 200) {
      return Category.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create category: ${response.statusCode}');
    }
  }

  Future<Category> updateCategory(Category category) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/${category.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(category.toJson()),
    );
    if (response.statusCode == 200) {
      return Category.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update category: ${response.statusCode}');
    }
  }

  Future<void> deleteCategory(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete category: ${response.statusCode}');
    }
  }
}
