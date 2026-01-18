import '../../../../core/constants/bible_order.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/repositories/bible_repository.dart';
import '../datasources/bible_local_datasource.dart';
import '../datasources/bible_remote_datasource.dart';

class BibleRepositoryImpl implements BibleRepository {
  final BibleRemoteDataSource _remoteDataSource;
  final BibleLocalDataSource _localDataSource;

  BibleRepositoryImpl({
    required BibleRemoteDataSource remoteDataSource,
    required BibleLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  @override
  Future<Map<String, List<BookEntity>>> getBooks() async {
    try {
      final cached = await _localDataSource.getCachedBooks();
      if (cached != null) return _sortBooks(cached);

      final remote = await _remoteDataSource.fetchBooks();
      await _localDataSource.cacheBooks(remote);
      return _sortBooks(remote);
    } catch (e) {
      try {
        final cached = await _localDataSource.getCachedBooks();
        if (cached != null) return _sortBooks(cached);
      } catch (_) {}
      rethrow;
    }
  }

  Map<String, List<BookEntity>> _sortBooks(
    Map<String, List<BookEntity>> books,
  ) {
    final Map<String, List<BookEntity>> sorted = {"at": [], "nt": []};

    void sortList(String key, List<String> order) {
      final list = books[key] ?? [];
      for (final id in order) {
        final book = list.where((b) => b.id == id).firstOrNull;
        if (book != null) sorted[key]!.add(book);
      }
      // Add extras
      for (final book in list) {
        if (!order.contains(book.id)) sorted[key]!.add(book);
      }
    }

    sortList('at', BibleOrder.atOrder);
    sortList('nt', BibleOrder.ntOrder);
    return sorted;
  }

  @override
  Future<Map<String, String>> getChapter(String bookId, int chapterNum) async {
    try {
      final cached = await _localDataSource.getCachedChapter(
        bookId,
        chapterNum,
      );
      if (cached != null) return cached;

      final remote = await _remoteDataSource.fetchChapter(bookId, chapterNum);
      await _localDataSource.cacheChapter(bookId, chapterNum, remote);
      return remote;
    } catch (e) {
      try {
        final cached = await _localDataSource.getCachedChapter(
          bookId,
          chapterNum,
        );
        if (cached != null) return cached;
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<Map<String, String>> getFootnotes(
    String bookId,
    int chapterNum,
  ) async {
    try {
      final cached = await _localDataSource.getCachedFootnotes(
        bookId,
        chapterNum,
      );
      if (cached != null) return cached;

      final remote = await _remoteDataSource.fetchFootnotes(bookId, chapterNum);
      await _localDataSource.cacheFootnotes(bookId, chapterNum, remote);
      return remote;
    } catch (e) {
      try {
        final cached = await _localDataSource.getCachedFootnotes(
          bookId,
          chapterNum,
        );
        if (cached != null) return cached;
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<Map<String, String>> getHighlights(String bookId, int chapterNum) {
    return _localDataSource.getHighlights(bookId, chapterNum);
  }

  @override
  Future<void> toggleHighlight(
    String bookId,
    int chapterNum,
    String verseNum, {
    String? color,
  }) async {
    if (color == null) {
      await _localDataSource.removeHighlight(bookId, chapterNum, verseNum);
    } else {
      await _localDataSource.saveHighlight(bookId, chapterNum, verseNum, color);
    }
  }

  @override
  Future<void> saveLastRead(String bookId, String bookName, int chapterNum) {
    return _localDataSource.saveLastRead(bookId, bookName, chapterNum);
  }

  @override
  Future<Map<String, dynamic>?> getLastRead() {
    return _localDataSource.getLastRead();
  }

  @override
  Future<void> saveReaderSettings(Map<String, dynamic> settings) {
    return _localDataSource.saveReaderSettings(settings);
  }

  @override
  Future<Map<String, dynamic>?> getReaderSettings() {
    return _localDataSource.getReaderSettings();
  }
}
