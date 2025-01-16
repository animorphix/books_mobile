import 'dart:convert';
import 'package:flutter_books_app/config.dart';
import 'package:http/http.dart' as http;

class ApiService {

  // возможно использовать в дальнейшем OpenLibrary API?
  static const String booksApiUrl =
      'https://openlibrary.org/search.json?title=flutter'; 
  static const baseUrl = Config.baseUrl;

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

  static Future<http.Response> fetchBooks() async {
    final url = Uri.parse(booksApiUrl);
    final response = await http.get(url);
    return response;
  }
}
