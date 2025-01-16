// services/nyt_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class NytBook {
  final String title;
  final String author;
  final String description;
  final String imageUrl;
  final String publisher;
  final String amazonLink;
  
  final String primaryIsbn13;
  final String primaryIsbn10;

  NytBook({
    required this.title,
    required this.author,
    required this.description,
    required this.imageUrl,
    required this.publisher,
    required this.amazonLink,
    required this.primaryIsbn13,
    required this.primaryIsbn10,
  });

  factory NytBook.fromJson(Map<String, dynamic> json) {
    return NytBook(
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['book_image'] ?? '', // Может оказаться пустым
      publisher: json['publisher'] ?? '',
      amazonLink: json['amazon_product_url'] ?? '',
      primaryIsbn13: json['primary_isbn13'] ?? '',
      primaryIsbn10: json['primary_isbn10'] ?? '',
    );
  }
}

class NytService {
  static const String _baseUrl = 'https://api.nytimes.com/svc/books/v3';
  static const String _apiKey = '76a1hTmPdGf7GyXgBl4y6JMGdzmIDODW'; 

  static Future<List<NytBook>> fetchBestSellerBooks({
    String listName = 'hardcover-fiction',
  }) async {
    final url = Uri.parse('$_baseUrl/lists/current/$listName.json?api-key=$_apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'];
      if (results != null && results['books'] != null) {
        final booksJson = results['books'] as List;
        return booksJson.map((item) => NytBook.fromJson(item)).toList();
      } else {
        return [];
      }
    } else {
      throw Exception(
        'Ошибка NYTimes: ${response.statusCode} -> ${response.body}',
      );
    }
  }

  static Future<NytBook?> fetchBookByIsbn(String isbn) async {
    final url = Uri.parse('$_baseUrl/lists/best-sellers/history.json?isbn=$isbn&api-key=$_apiKey');
        print(url);
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final results = data['results'] as List?;
      if (results == null || results.isEmpty) {
        return null;
      }
      final first = results.first as Map<String, dynamic>;

      final mapped = {
        'title': first['title'] ?? '',
        'author': first['author'] ?? '',
        'description': first['description'] ?? '',
        'book_image': '', 
        'publisher': first['publisher'] ?? '',
        'amazon_product_url': '', 
        'primary_isbn13': '', 
        'primary_isbn10': '',
      };

      // Если хотите достать isbn10/13:
      if (first['isbns'] != null && (first['isbns'] as List).isNotEmpty) {
        final firstIsbn = (first['isbns'] as List).first;
        if (firstIsbn is Map) {
          mapped['primary_isbn13'] = firstIsbn['isbn13'] ?? '';
          mapped['primary_isbn10'] = firstIsbn['isbn10'] ?? '';
        }
      }

      return NytBook.fromJson(mapped);
    } else {
      throw Exception('NYT error: ${response.statusCode}');
    }
  }
}
