import '../../domain/entities/book_entity.dart';

abstract class BibleRepository {
  Future<Map<String, List<BookEntity>>> getBooks();
  Future<Map<String, String>> getChapter(String bookId, int chapterNum);
  Future<Map<String, String>> getFootnotes(String bookId, int chapterNum);

  // Highlights
  Future<Map<String, String>> getHighlights(String bookId, int chapterNum);
  Future<void> toggleHighlight(
    String bookId,
    int chapterNum,
    String verseNum, {
    String? color,
  });

  // State Persistence
  Future<void> saveLastRead(String bookId, String bookName, int chapterNum);
  Future<Map<String, dynamic>?> getLastRead();

  // Reader Settings
  Future<void> saveReaderSettings(Map<String, dynamic> settings);
  Future<Map<String, dynamic>?> getReaderSettings();
}
