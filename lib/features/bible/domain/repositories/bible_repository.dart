import '../../domain/entities/book_entity.dart';

abstract class BibleRepository {
  Future<Map<String, List<BookEntity>>> getBooks();
  Future<Map<String, String>> getChapter(String bookId, int chapterNum);
  Future<Map<String, String>> getFootnotes(String bookId, int chapterNum);
}
