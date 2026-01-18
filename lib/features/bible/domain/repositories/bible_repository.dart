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
}
