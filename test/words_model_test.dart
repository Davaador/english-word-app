import 'package:flutter_test/flutter_test.dart';
import 'package:english_words_app/api.dart';
import 'package:english_words_app/words_model.dart';

Word makeWord(String en, String category, String level) {
  return Word(en: en, mn: '', category: category, level: level);
}

void main() {
  final sample = [
    makeWord('tag', 'web', 'easy'),
    makeWord('style', 'css', 'easy'),
    makeWord('margin', 'css', 'medium'),
    makeWord('deploy', 'devops', 'hard'),
  ];

  WordsModel modelWithSample() {
    return WordsModel(
      fetcher: () async => (words: sample, fromCache: false),
    );
  }

  test('load stores the words and stops loading', () async {
    final model = modelWithSample();
    await model.load();

    expect(model.loading, false);
    expect(model.allWords.length, 4);
    expect(model.fromCache, false);
    expect(model.error, isNull);
  });

  test('categories start with all and have no duplicates', () async {
    final model = modelWithSample();
    await model.load();

    expect(model.categories, ['all', 'web', 'css', 'devops']);
  });

  test('filter by category', () async {
    final model = modelWithSample();
    await model.load();
    model.setCategory('css');

    expect(model.filtered.length, 2);
  });

  test('filter by category and level', () async {
    final model = modelWithSample();
    await model.load();
    model.setCategory('css');
    model.setLevel('medium');

    expect(model.filtered.length, 1);
    expect(model.filtered.first.en, 'margin');
  });

  test('load sets an error when the fetch fails', () async {
    final model = WordsModel(
      fetcher: () async => throw ApiException('boom'),
    );
    await model.load();

    expect(model.loading, false);
    expect(model.error, isNotNull);
    expect(model.allWords, isEmpty);
  });

  test('model tells listeners when the category changes', () async {
    final model = modelWithSample();
    await model.load();

    var calls = 0;
    model.addListener(() => calls++);
    model.setCategory('web');

    expect(calls, 1);
  });
}