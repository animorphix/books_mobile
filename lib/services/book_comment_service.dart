import 'dart:convert';
import 'package:flutter_books_app/config.dart';
import 'package:http/http.dart' as http;

class CommentModel {
  final int id;
  final int userId;
  final String isbn;
  final String content;

  CommentModel({
    required this.id,
    required this.userId,
    required this.isbn,
    required this.content,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      userId: json['user_id'],
      isbn: json['isbn'],
      content: json['content'],
    );
  }
}

class CommentService {
  static const String baseUrl = Config.baseUrl; 
  // Пример: GET /comments
  //         POST /comments
  //         PATCH /comments/:id
  //         DELETE /comments/:id
  // и т.д.

  // Получить все комментарии текущего пользователя
  static Future<http.Response> getComments({required String token}) async {
    final url = Uri.parse('$baseUrl/comments');
    return http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

  // Создать комментарий (isbn + content)
  static Future<http.Response> createComment({
    required String token,
    required String isbn,
    required String content,
  }) async {
    final url = Uri.parse('$baseUrl/comments');
    final body = jsonEncode({
      'comment': {
        'isbn': isbn,
        'content': content,
      }
    });
    final response = http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    return response;
  }

  static Future<http.Response> updateComment({
    required String token,
    required int commentId,
    required String newContent,
  }) async {
    final url = Uri.parse('$baseUrl/comments/$commentId');
    final body = jsonEncode({
      'comment': {
        'content': newContent,
      }
    });
    final response = http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    return response;
  }

  static Future<http.Response> deleteComment({
    required String token,
    required int commentId,
  }) async {
    final url = Uri.parse('$baseUrl/comments/$commentId');
    final response = http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }
}
