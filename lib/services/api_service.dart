import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:3000'; 

  // возможно использовать в дальнейшем OpenLibrary API?
  static const String booksApiUrl =
      'https://openlibrary.org/search.json?title=flutter'; 

  // Пример регистрации
  static Future<http.Response> signUp({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/signup');
    final body = jsonEncode({
      "user": {
        "email": email,
        "password": password,
      }
    });
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    return response;
  }

  // Пример авторизации
  static Future<http.Response> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');
    final body = jsonEncode({
      "user": {
        "email": email,
        "password": password,
      }
    });
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    return response;
  }

  // Пример выхода
  static Future<http.Response> logout({required String token}) async {
    final url = Uri.parse('$baseUrl/logout');
    final response = await http.delete(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    return response;
  }

  // Получение статусов чтения
  static Future<http.Response> getReadingStatuses({required String token}) async {
    final url = Uri.parse('$baseUrl/reading_statuses');
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    return response;
  }

  // Создание нового статуса
  static Future<http.Response> createReadingStatus({
    required String token,
    required String isbn,
    required String status,
  }) async {
    final url = Uri.parse('$baseUrl/reading_statuses');
    final body = jsonEncode({
      "reading_status": {
        "isbn": isbn,
        "status": status,
      }
    });

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );
    return response;
  }

  // Обновление существующего статуса
  static Future<http.Response> updateReadingStatus({
    required String token,
    required int statusId,
    required String newStatus,
  }) async {
    final url = Uri.parse('$baseUrl/reading_statuses/$statusId');
    final body = jsonEncode({
      "reading_status": {
        "status": newStatus,
      }
    });

    final response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );
    return response;
  }

  // Удаление статуса
  static Future<http.Response> deleteReadingStatus({
    required String token,
    required int statusId,
  }) async {
    final url = Uri.parse('$baseUrl/reading_statuses/$statusId');
    final response = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    return response;
  }

  // Пример получения списка книг из внешнего API
  static Future<http.Response> fetchBooks() async {
    final url = Uri.parse(booksApiUrl);
    final response = await http.get(url);
    return response;
  }
}
