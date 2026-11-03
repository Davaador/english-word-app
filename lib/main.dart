import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

const apiUrl = 'https://words-api-1jvo.onrender.com/api/words';

void main() {
  runApp(const MyApp());
}

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

Future<List<Word>> fetchWords() async {
  final response = await http.get(Uri.parse(apiUrl));
  if (response.statusCode != 200) {
    throw Exception('Server error: ${response.statusCode}');
  }
  final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
  return data.map((item) => Word.fromJson(item)).toList();
}

List<Word> dailyWords(List<Word> all) {
  if (all.isEmpty) return [];
  final now = DateTime.now();
  final localMs =
      now.millisecondsSinceEpoch + now.timeZoneOffset.inMilliseconds;
  final day = localMs ~/ 86400000;
  final start = (day * 5) % all.length;
  final count = all.length < 5 ? all.length : 5;
  return [for (var i = 0; i < count; i++) all[(start + i) % all.length]];
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My English Words',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2A6DF4),
        useMaterial3: true,
      ),
      home: const WordListPage(),
    );
  }
}

class WordListPage extends StatefulWidget {
  const WordListPage({super.key});

  @override
  State<WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage> {
  late Future<List<Word>> futureWords;
  List<Word> _allWords = [];
  String _category = 'all';
  String _level = 'all';

  @override
  void initState() {
    super.initState();
    futureWords = fetchWords().then((words) {
      _allWords = words;
      return words;
    });
  }

  List<Word> get _filtered {
    return _allWords.where((w) {
      final categoryOk = _category == 'all' || w.category == _category;
      final levelOk = _level == 'all' || w.level == _level;
      return categoryOk && levelOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My English Words'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Daily 5',
            onPressed: () {
              final words = dailyWords(_allWords);
              if (words.isEmpty) return;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QuizPage(words: words)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.quiz),
            onPressed: () {
              final words = _filtered;
              if (words.isEmpty) return;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QuizPage(words: words)),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Word>>(
        future: futureWords,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final categories = <String>[
            'all',
            ...{..._allWords.map((w) => w.category).where((c) => c.isNotEmpty)},
          ];
          final words = _filtered;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _category,
                        isExpanded: true,
                        items: categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _category = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _level,
                        isExpanded: true,
                        items: ['all', 'easy', 'medium', 'hard']
                            .map(
                              (l) => DropdownMenuItem(value: l, child: Text(l)),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _level = value!),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: words.isEmpty
                    ? const Center(child: Text('No words here'))
                    : ListView.builder(
                        itemCount: words.length,
                        itemBuilder: (context, index) {
                          final word = words[index];
                          return ListTile(
                            title: Text(word.en),
                            subtitle: Text(word.mn),
                            trailing: Text(word.level),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  final List<Word> words;
  const QuizPage({super.key, required this.words});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final _controller = TextEditingController();
  final _random = Random();
  int _index = 0;
  int _score = 0;
  int _best = 0;
  bool _answered = false;
  String _result = '';

  @override
  void initState() {
    super.initState();
    _index = _random.nextInt(widget.words.length);
    _loadBest();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _best = prefs.getInt('bestScore') ?? 0;
    });
  }

  Future<void> _saveBest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bestScore', _best);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    if (_answered) return;
    final answer = _controller.text.trim().toLowerCase();
    final correct = widget.words[_index].en.toLowerCase();
    setState(() {
      _answered = true;
      if (answer == correct) {
        _score++;
        _result = 'Correct!';
        if (_score > _best) {
          _best = _score;
          _saveBest();
        }
      } else {
        _result = 'Wrong. Answer: ${widget.words[_index].en}';
      }
    });
  }

  void _next() {
    setState(() {
      _index = _random.nextInt(widget.words.length);
      _answered = false;
      _result = '';
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.words[_index];
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              word.mn,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter English word',
              ),
              onSubmitted: (_) => _check(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _check,
                    child: Text('Check'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _next,
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _result,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: _result == 'Correct!' ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text('Score: $_score', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Score: $_score   Best: $_best',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
