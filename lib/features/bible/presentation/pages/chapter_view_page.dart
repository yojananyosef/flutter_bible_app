import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../domain/repositories/bible_repository.dart';

class ChapterViewPage extends StatefulWidget {
  final String bookId;
  final String bookName;
  final int chapterNum;
  final BibleRepository repository;

  const ChapterViewPage({
    super.key,
    required this.bookId,
    required this.bookName,
    required this.chapterNum,
    required this.repository,
  });

  @override
  State<ChapterViewPage> createState() => _ChapterViewPageState();
}

class _ChapterViewPageState extends State<ChapterViewPage> {
  Map<String, String>? _verses;
  Map<String, String>? _footnotes;
  Map<String, String> _highlights = {}; // verseNum -> colorHex
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
        widget.repository.getChapter(widget.bookId, widget.chapterNum),
        widget.repository.getFootnotes(widget.bookId, widget.chapterNum),
        widget.repository.getHighlights(widget.bookId, widget.chapterNum),
      ]);
      if (mounted) {
        setState(() {
          _verses = results[0];
          _footnotes = results[1];
          _highlights = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleHighlight(String verseNum, String? colorHex) async {
    // If same color, remove highlight
    final finalColor = _highlights[verseNum] == colorHex ? null : colorHex;

    await widget.repository.toggleHighlight(
      widget.bookId,
      widget.chapterNum,
      verseNum,
      color: finalColor,
    );

    final newHighlights = await widget.repository.getHighlights(
      widget.bookId,
      widget.chapterNum,
    );
    setState(() {
      _highlights = newHighlights;
    });
  }

  void _showHighlightMenu(String verseNum) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Resaltar versículo $verseNum'),
        actions: [
          _buildColorOption('Amarillo', '0xFFFFF176', verseNum),
          _buildColorOption('Verde', '0xFFAED581', verseNum),
          _buildColorOption('Azul', '0xFF81D4FA', verseNum),
          _buildColorOption('Rosa', '0xFFF48FB1', verseNum),
          _buildColorOption('Naranja', '0xFFFFB74D', verseNum),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  Widget _buildColorOption(String label, String hex, String verseNum) {
    final color = Color(int.parse(hex));
    final isSelected = _highlights[verseNum] == hex;

    return CupertinoActionSheetAction(
      onPressed: () {
        Navigator.pop(context);
        _toggleHighlight(verseNum, hex);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: CupertinoColors.separator),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.check_mark, size: 16),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('${widget.bookName} ${widget.chapterNum}'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _error != null
            ? Center(child: Text('Error: $_error'))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ..._buildVerses(),
                  if (_footnotes != null && _footnotes!.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(color: CupertinoColors.separator),
                    ),
                    const Text(
                      'Notas al pie',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildFootnotes(),
                  ],
                ],
              ),
      ),
    );
  }

  List<Widget> _buildVerses() {
    final sortedKeys = _verses!.keys.toList()..sort(_compareKeys);
    return sortedKeys.map((key) {
      final highlightHex = _highlights[key];
      final highlightColor = highlightHex != null
          ? Color(int.parse(highlightHex))
          : null;

      return GestureDetector(
        onTap: () => _showHighlightMenu(key),
        child: Container(
          decoration: BoxDecoration(
            color: highlightColor?.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$key ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.activeBlue,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: _verses![key],
                  style: const TextStyle(
                    fontSize: 17,
                    color: CupertinoColors.black,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildFootnotes() {
    final sortedKeys = _footnotes!.keys.toList()..sort(_compareKeys);
    return sortedKeys.map((key) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Text(
          '$key: ${_footnotes![key]}',
          style: const TextStyle(
            fontSize: 14,
            color: CupertinoColors.secondaryLabel,
            fontStyle: FontStyle.italic,
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
