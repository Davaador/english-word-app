import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const apiUrl = 'https://words-api-1jvo.onrender.com/api/words';
const checkUrl = 'https://words-api-1jvo.onrender.com/api/check';

class Word {
  final String en;
  final String mn;
  final String category;
  final String level;

  Word({
    required this.en,
    required this.mn,
    required this.category,
    required this.level,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      en: json['en'] ?? '',
      mn: json['mn'] ?? '',
      category: json['category'] ?? '',
      level: json['level'] ?? '',
    );
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
}

typedef WordsResult = ({List<Word> words, bool fromCache});

List<Word> _parseWords(String body) {
  final List<dynamic> data = jsonDecode(body);
  return data.map((item) => Word.fromJson(item)).toList();
}

Future<WordsResult> fetchWords() async {
  final prefs = await SharedPreferences.getInstance();
  try {
    final response = await http
        .get(Uri.parse(apiUrl))
        .timeout(const Duration(seconds: 90));
    if (response.statusCode != 200) {
      throw ApiException('Server error: ${response.statusCode}');
    }
    final body = utf8.decode(response.bodyBytes);
    await prefs.setString('wordsCache', body);
    return (words: _parseWords(body), fromCache: false);
  } catch (e) {
    final cached = prefs.getString('wordsCache');
    if (cached != null) {
      return (words: _parseWords(cached), fromCache: true);
    }
    rethrow;
  }
}

Future<String> checkSentence(String sentence) async {
  final response = await http
      .post(
        Uri.parse(checkUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sentence': sentence}),
      )
      .timeout(const Duration(seconds: 90));
  if (response.statusCode == 429) {
    throw ApiException('Too many requests. Try again in a minute.');
  }
  if (response.statusCode != 200) {
    throw ApiException('Server error: ${response.statusCode}');
  }
  final data = jsonDecode(utf8.decode(response.bodyBytes));
  return data['feedback'] as String;
}