import 'package:hive_flutter/hive_flutter.dart';
import '../models/book_model.dart';

abstract class BibleLocalDataSource {
  Future<void> cacheBooks(Map<String, List<BookModel>> books);
  Future<Map<String, List<BookModel>>?> getCachedBooks();

  Future<void> cacheChapter(
    String bookId,
    int chapterNum,
    Map<String, String> verses,
  );
  Future<Map<String, String>?> getCachedChapter(String bookId, int chapterNum);

  Future<void> cacheFootnotes(
    String bookId,
    int chapterNum,
    Map<String, String> footnotes,
  );
  Future<Map<String, String>?> getCachedFootnotes(
    String bookId,
    int chapterNum,
  );

  // Highlights
  Future<void> saveHighlight(
    String bookId,
    int chapterNum,
    String verseNum,
    String color,
  );
  Future<void> removeHighlight(String bookId, int chapterNum, String verseNum);
  Future<Map<String, String>> getHighlights(String bookId, int chapterNum);

  // State Persistence
  Future<void> saveLastRead(String bookId, String bookName, int chapterNum);
  Future<Map<String, dynamic>?> getLastRead();

  // Reader Settings
  Future<void> saveReaderSettings(Map<String, double> settings);
  Future<Map<String, double>?> getReaderSettings();
}

class BibleLocalDataSourceImpl implements BibleLocalDataSource {
  static const String booksBoxName = 'bible_books';
  static const String chaptersBoxName = 'bible_chapters';
  static const String footnotesBoxName = 'bible_footnotes';
  static const String highlightsBoxName = 'bible_highlights';
  static const String stateBoxName = 'bible_state';

  @override
  Future<void> cacheBooks(Map<String, List<BookModel>> books) async {
    final box = await Hive.openBox(booksBoxName);
    // Convert to simple map for Hive
    final Map<String, List<Map<String, dynamic>>> dataToCache = {
      'at': books['at']!.map((e) => e.toJson()).toList(),
      'nt': books['nt']!.map((e) => e.toJson()).toList(),
    };
    await box.put('metadata', dataToCache);
  }

  @override
  Future<Map<String, List<BookModel>>?> getCachedBooks() async {
    final box = await Hive.openBox(booksBoxName);
    final data = box.get('metadata');
    if (data == null) return null;

    final Map<dynamic, dynamic> castedData = data as Map;
    return {
      'at': (castedData['at'] as List)
          .map((e) => BookModel.fromJson(e['id'], Map<String, dynamic>.from(e)))
          .toList(),
      'nt': (castedData['nt'] as List)
          .map((e) => BookModel.fromJson(e['id'], Map<String, dynamic>.from(e)))
          .toList(),
    };
  }

  @override
  Future<void> cacheChapter(
    String bookId,
    int chapterNum,
    Map<String, String> verses,
  ) async {
    final box = await Hive.openBox(chaptersBoxName);
    await box.put('$bookId-$chapterNum', verses);
  }

  @override
  Future<Map<String, String>?> getCachedChapter(
    String bookId,
    int chapterNum,
  ) async {
    final box = await Hive.openBox(chaptersBoxName);
    final data = box.get('$bookId-$chapterNum');
    if (data == null) return null;
    return Map<String, String>.from(data);
  }

  @override
  Future<void> cacheFootnotes(
    String bookId,
    int chapterNum,
    Map<String, String> footnotes,
  ) async {
    final box = await Hive.openBox(footnotesBoxName);
    await box.put('$bookId-$chapterNum', footnotes);
  }

  @override
  Future<Map<String, String>?> getCachedFootnotes(
    String bookId,
    int chapterNum,
  ) async {
    final box = await Hive.openBox(footnotesBoxName);
    final data = box.get('$bookId-$chapterNum');
    if (data == null) return null;
    return Map<String, String>.from(data);
  }

  @override
  Future<void> saveHighlight(
    String bookId,
    int chapterNum,
    String verseNum,
    String color,
  ) async {
    final box = await Hive.openBox(highlightsBoxName);
    final Map<String, String> highlights = Map<String, String>.from(
      box.get('$bookId-$chapterNum') ?? {},
    );
    highlights[verseNum] = color;
    await box.put('$bookId-$chapterNum', highlights);
  }

  @override
  Future<void> removeHighlight(
    String bookId,
    int chapterNum,
    String verseNum,
  ) async {
    final box = await Hive.openBox(highlightsBoxName);
    final Map<String, String> highlights = Map<String, String>.from(
      box.get('$bookId-$chapterNum') ?? {},
    );
    highlights.remove(verseNum);
    await box.put('$bookId-$chapterNum', highlights);
  }

  @override
  Future<Map<String, String>> getHighlights(
    String bookId,
    int chapterNum,
  ) async {
    final box = await Hive.openBox(highlightsBoxName);
    final data = box.get('$bookId-$chapterNum');
    if (data == null) return {};
    return Map<String, String>.from(data);
  }

  @override
  Future<void> saveLastRead(
    String bookId,
    String bookName,
    int chapterNum,
  ) async {
    final box = await Hive.openBox(stateBoxName);
    await box.put('last_read', {
      'bookId': bookId,
      'bookName': bookName,
      'chapterNum': chapterNum,
    });
  }

  @override
  Future<Map<String, dynamic>?> getLastRead() async {
    final box = await Hive.openBox(stateBoxName);
    final data = box.get('last_read');
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  @override
  Future<void> saveReaderSettings(Map<String, double> settings) async {
    final box = await Hive.openBox(stateBoxName);
    await box.put('reader_settings', settings);
  }

  @override
  Future<Map<String, double>?> getReaderSettings() async {
    final box = await Hive.openBox(stateBoxName);
    final data = box.get('reader_settings');
    if (data == null) return null;
    return Map<String, double>.from(data);
  }
}
