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
}

class BibleLocalDataSourceImpl implements BibleLocalDataSource {
  static const String booksBoxName = 'bible_books';
  static const String chaptersBoxName = 'bible_chapters';
  static const String footnotesBoxName = 'bible_footnotes';

  @override
  Future<void> cacheBooks(Map<String, List<BookModel>> books) async {
    final box = Hive.box(booksBoxName);
    // Convert to simple map for Hive
    final Map<String, List<Map<String, dynamic>>> dataToCache = {
      'at': books['at']!.map((e) => e.toJson()).toList(),
      'nt': books['nt']!.map((e) => e.toJson()).toList(),
    };
    await box.put('metadata', dataToCache);
  }

  @override
  Future<Map<String, List<BookModel>>?> getCachedBooks() async {
    final box = Hive.box(booksBoxName);
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
    final box = Hive.box(chaptersBoxName);
    await box.put('$bookId-$chapterNum', verses);
  }

  @override
  Future<Map<String, String>?> getCachedChapter(
    String bookId,
    int chapterNum,
  ) async {
    final box = Hive.box(chaptersBoxName);
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
    final box = Hive.box(footnotesBoxName);
    await box.put('$bookId-$chapterNum', footnotes);
  }

  @override
  Future<Map<String, String>?> getCachedFootnotes(
    String bookId,
    int chapterNum,
  ) async {
    final box = Hive.box(footnotesBoxName);
    final data = box.get('$bookId-$chapterNum');
    if (data == null) return null;
    return Map<String, String>.from(data);
  }
}
