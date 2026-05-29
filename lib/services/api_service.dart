import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/task.dart';

class ApiService {
  // Ambil token dari storage
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Simpan token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Hapus token
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }

  // Headers dengan token
  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type':  'application/json',
      'Accept':        'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // LOGIN
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/login'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await saveToken(data['token']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', data['user']['name']);
      await prefs.setString('user_email', data['user']['email']);
    }

    return {'status': response.statusCode, 'data': data};
  }

  // LOGOUT
  Future<void> logout() async {
    final headers = await getHeaders();
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/logout'),
      headers: headers,
    );
    await removeToken();
  }

  // GET ALL TASKS
  Future<List<Task>> getTasks() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/tasks'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Task.fromJson(e)).toList();
    }
    return [];
  }

  // GET TASK DETAIL
  Future<Task?> getTask(int id) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/tasks/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  // CREATE TASK
  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/tasks'),
      headers: headers,
      body: jsonEncode(data),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  // UPDATE TASK
  Future<Map<String, dynamic>> updateTask(int id, Map<String, dynamic> data) async {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/tasks/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  // DELETE TASK
  Future<bool> deleteTask(int id) async {
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/tasks/$id'),
      headers: headers,
    );
    return response.statusCode == 200;
  }
}