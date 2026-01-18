import 'package:flutter/cupertino.dart';
import '../../domain/repositories/bible_repository.dart';
import '../../domain/entities/book_entity.dart';

class SelectionModal extends StatefulWidget {
  final BibleRepository repository;
  final String? currentBookId;
  final int? currentChapterNum;

  const SelectionModal({
    super.key,
    required this.repository,
    this.currentBookId,
    this.currentChapterNum,
  });

  @override
  State<SelectionModal> createState() => _SelectionModalState();
}

class _SelectionModalState extends State<SelectionModal> {
  List<BookEntity> _allBooks = [];
  int _selectedBookIndex = 0;
  int _selectedChapterIndex = 0;
  bool _isLoading = true;

  late FixedExtentScrollController _bookController;
  late FixedExtentScrollController _chapterController;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final booksMap = await widget.repository.getBooks();
    final combinedBooks = [...booksMap['at']!, ...booksMap['nt']!];

    int bookIndex = 0;
    int chapterIndex = 0;

    if (widget.currentBookId != null) {
      bookIndex = combinedBooks.indexWhere((b) => b.id == widget.currentBookId);
      if (bookIndex == -1) bookIndex = 0;
      chapterIndex = (widget.currentChapterNum ?? 1) - 1;
    }

    _bookController = FixedExtentScrollController(initialItem: bookIndex);
    _chapterController = FixedExtentScrollController(initialItem: chapterIndex);

    setState(() {
      _allBooks = combinedBooks;
      _selectedBookIndex = bookIndex;
      _selectedChapterIndex = chapterIndex;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _bookController.dispose();
    _chapterController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (_allBooks.isEmpty) return;

    final book = _allBooks[_selectedBookIndex];
    Navigator.pop(context, {
      'bookId': book.id,
      'bookName': book.nombre,
      'chapterNum': _selectedChapterIndex + 1,
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGroupedBackground.withOpacity(
          0.8,
        ),
        middle: const Text(
          'Ir a...',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _buildDoublePicker(),
    );
  }

  Widget _buildDoublePicker() {
    final currentBook = _allBooks[_selectedBookIndex];
    final totalChapters = currentBook.capitulos;

    return Column(
      children: [
        const SizedBox(height: 32),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                'LIBRO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.secondaryLabel,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                'CAPÍTULO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.secondaryLabel,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              // Book Picker
              Expanded(
                flex: 3,
                child: CupertinoPicker(
                  scrollController: _bookController,
                  itemExtent: 44.0,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedBookIndex = index;
                      // Ensure chapter index doesn't exceed new book's chapters
                      final newChapters = _allBooks[index].capitulos;
                      if (_selectedChapterIndex >= newChapters) {
                        _selectedChapterIndex = newChapters - 1;
                        _chapterController.jumpToItem(_selectedChapterIndex);
                      }
                    });
                  },
                  children: _allBooks.map((book) {
                    return Center(
                      child: Text(
                        book.nombre,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Chapter Picker
              Expanded(
                flex: 2,
                child: CupertinoPicker(
                  key: ValueKey('chapters_of_${currentBook.id}'),
                  scrollController: _chapterController,
                  itemExtent: 44.0,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedChapterIndex = index;
                    });
                  },
                  children: List.generate(totalChapters, (i) {
                    final chapterNum = i + 1;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _selectedChapterIndex = i;
                        });
                        _onConfirm();
                      },
                      child: Center(
                        child: Text(
                          '$chapterNum',
                          style: TextStyle(
                            fontSize: 20,
                            color: _selectedChapterIndex == i
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.label,
                            fontWeight: _selectedChapterIndex == i
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 64),
      ],
    );
  }
}
