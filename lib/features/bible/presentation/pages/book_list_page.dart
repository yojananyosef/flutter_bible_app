import 'package:flutter/cupertino.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/repositories/bible_repository.dart';
import '../widgets/ios_list_items.dart';
import 'chapter_view_page.dart';

class BookListPage extends StatefulWidget {
  final BibleRepository repository;

  const BookListPage({super.key, required this.repository});

  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  Map<String, List<BookEntity>>? _testamentos;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final books = await widget.repository.getBooks();
      setState(() {
        _testamentos = books;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(largeTitle: Text('La Biblia')),
          SliverToBoxAdapter(
            child: _isLoading
                ? const SizedBox(
                    height: 300,
                    child: Center(child: CupertinoActivityIndicator()),
                  )
                : _error != null
                ? Center(child: Text('Error: $_error'))
                : Column(
                    children: [
                      IosListSection(
                        title: 'Antiguo Testamento',
                        children: _testamentos!['at']!.asMap().entries.map((
                          entry,
                        ) {
                          final index = entry.key;
                          final book = entry.value;
                          return IosListTile(
                            title: book.nombre,
                            subtitle: '${book.capitulos} capítulos',
                            isLast: index == _testamentos!['at']!.length - 1,
                            onTap: () => _navigateToChapters(book),
                          );
                        }).toList(),
                      ),
                      IosListSection(
                        title: 'Nuevo Testamento',
                        children: _testamentos!['nt']!.asMap().entries.map((
                          entry,
                        ) {
                          final index = entry.key;
                          final book = entry.value;
                          return IosListTile(
                            title: book.nombre,
                            subtitle: '${book.capitulos} capítulos',
                            isLast: index == _testamentos!['nt']!.length - 1,
                            onTap: () => _navigateToChapters(book),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _navigateToChapters(BookEntity book) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) =>
            ChapterListPage(book: book, repository: widget.repository),
      ),
    );
  }
}

class ChapterListPage extends StatelessWidget {
  final BookEntity book;
  final BibleRepository repository;

  const ChapterListPage({
    super.key,
    required this.book,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(book.nombre)),
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: book.capitulos,
        itemBuilder: (context, index) {
          final chapterNum = index + 1;
          return CupertinoButton(
            padding: EdgeInsets.zero,
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            onPressed: () => Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => ChapterViewPage(
                  bookId: book.id,
                  bookName: book.nombre,
                  chapterNum: chapterNum,
                  repository: repository,
                ),
              ),
            ),
            child: Text(
              '$chapterNum',
              style: const TextStyle(
                color: CupertinoColors.activeBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}
