import 'package:flutter/material.dart';
import 'services/bible_service.dart';
import 'models/book.dart';

void main() {
  runApp(const BibleApp());
}

class BibleApp extends StatelessWidget {
  const BibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BibleService _bibleService = BibleService();
  Map<String, List<Book>>? _testamentos;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final books = await _bibleService.fetchBooks();
      setState(() {
        _testamentos = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Libros de la Biblia'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : ListView(
              children: [
                _buildSection('Antiguo Testamento', _testamentos!['at']!),
                _buildSection('Nuevo Testamento', _testamentos!['nt']!),
              ],
            ),
    );
  }

  Widget _buildSection(String title, List<Book> books) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ),
        ...books.map(
          (book) => ListTile(
            title: Text(book.nombre),
            subtitle: Text('${book.capitulos} capítulos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChapterListPage(book: book),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ChapterListPage extends StatelessWidget {
  final Book book;

  const ChapterListPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book.nombre)),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: book.capitulos,
        itemBuilder: (context, index) {
          final chapterNum = index + 1;
          return ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerseViewPage(
                  bookId: book.id,
                  bookName: book.nombre,
                  chapterNum: chapterNum,
                ),
              ),
            ),
            child: Text('$chapterNum'),
          );
        },
      ),
    );
  }
}

class VerseViewPage extends StatefulWidget {
  final String bookId;
  final String bookName;
  final int chapterNum;

  const VerseViewPage({
    super.key,
    required this.bookId,
    required this.bookName,
    required this.chapterNum,
  });

  @override
  State<VerseViewPage> createState() => _VerseViewPageState();
}

class _VerseViewPageState extends State<VerseViewPage> {
  final BibleService _bibleService = BibleService();
  Map<String, String>? _verses;
  Map<String, String>? _footnotes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChapter();
  }

  Future<void> _loadChapter() async {
    try {
      final results = await Future.wait([
        _bibleService.fetchChapter(widget.bookId, widget.chapterNum),
        _bibleService.fetchFootnotes(widget.bookId, widget.chapterNum),
      ]);
      setState(() {
        _verses = results[0];
        _footnotes = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.bookName} ${widget.chapterNum}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._buildVerses(),
                if (_footnotes != null && _footnotes!.isNotEmpty) ...[
                  const Divider(height: 32),
                  const Text(
                    'Notas al pie',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  ..._buildFootnotes(),
                ],
              ],
            ),
    );
  }

  List<Widget> _buildVerses() {
    final sortedKeys = _verses!.keys.toList()..sort(_compareKeys);
    final textStyle = Theme.of(context).textTheme.bodyLarge;

    return sortedKeys.map((key) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$key ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
              ),
              TextSpan(text: _verses![key], style: textStyle),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildFootnotes() {
    final sortedKeys = _footnotes!.keys.toList()..sort(_compareKeys);
    return sortedKeys.map((key) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          '* $key: ${_footnotes![key]}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: Colors.grey[700],
          ),
        ),
      );
    }).toList();
  }

  int _compareKeys(String a, String b) {
    int? aNum = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), ''));
    int? bNum = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), ''));

    if (aNum != null && bNum != null) {
      return aNum.compareTo(bNum);
    }
    return a.compareTo(b);
  }
}
