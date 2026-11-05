import 'package:flutter/foundation.dart';
import 'api.dart';

class WordsModel extends ChangeNotifier {
  List<Word> _allWords = [];
  String _category = 'all';
  String _level = 'all';
  bool _loading = true;
  bool _fromCache = false;
  String? _error;

  List<Word> get allWords => _allWords;
  String get category => _category;
  String get level => _level;
  bool get loading => _loading;
  bool get fromCache => _fromCache;
  String? get error => _error;
  final Future<WordsResult> Function() _fetcher;
  WordsModel({Future<WordsResult> Function()? fetcher})
      : _fetcher = fetcher ?? fetchWords;

  List<String> get categories => [
        'all',
        ...{..._allWords.map((w) => w.category).where((c) => c.isNotEmpty)},
      ];

  List<Word> get filtered {
    return _allWords.where((w) {
      final categoryOk = _category == 'all' || w.category == _category;
      final levelOk = _level == 'all' || w.level == _level;
      return categoryOk && levelOk;
    }).toList();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _fetcher();
      _allWords = result.words;
      _fromCache = result.fromCache;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void setLevel(String value) {
    _level = value;
    notifyListeners();
  }
}