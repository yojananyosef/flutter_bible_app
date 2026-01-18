import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../domain/repositories/bible_repository.dart';

import '../widgets/selection_modal.dart';
import '../widgets/reader_settings_modal.dart';

class ChapterViewPage extends StatefulWidget {
  final BibleRepository repository;
  final String initialBookId;
  final String initialBookName;
  final int initialChapterNum;

  const ChapterViewPage({
    super.key,
    required this.repository,
    this.initialBookId = 'GEN',
    this.initialBookName = 'Génesis',
    this.initialChapterNum = 1,
  });

  @override
  State<ChapterViewPage> createState() => _ChapterViewPageState();
}

class _ChapterViewPageState extends State<ChapterViewPage> {
  late String _bookId;
  late String _bookName;
  late int _chapterNum;

  Map<String, String>? _verses;
  Map<String, String>? _footnotes;
  Map<String, String> _highlights = {};
  bool _isLoading = true;
  String? _error;

  // Reader Settings
  double _fontSize = 18.0;
  double _lineHeight = 1.5;
  double _letterSpacing = 0.0;

  @override
  void initState() {
    super.initState();
    _bookId = widget.initialBookId;
    _bookName = widget.initialBookName;
    _chapterNum = widget.initialChapterNum;
    _loadChapter();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await widget.repository.getReaderSettings();
    if (settings != null) {
      setState(() {
        _fontSize = settings['fontSize'] ?? 18.0;
        _lineHeight = settings['lineHeight'] ?? 1.5;
        _letterSpacing = settings['letterSpacing'] ?? 0.0;
      });
    }
  }

  Future<void> _saveSettings() async {
    await widget.repository.saveReaderSettings({
      'fontSize': _fontSize,
      'lineHeight': _lineHeight,
      'letterSpacing': _letterSpacing,
    });
  }

  Future<void> _loadChapter() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        widget.repository.getChapter(_bookId, _chapterNum),
        widget.repository.getFootnotes(_bookId, _chapterNum),
        widget.repository.getHighlights(_bookId, _chapterNum),
      ]);

      // Save state
      await widget.repository.saveLastRead(_bookId, _bookName, _chapterNum);

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

  void _openSelector() async {
    final result = await showCupertinoModalPopup<Map<String, dynamic>>(
      context: context,
      builder: (context) => SelectionModal(
        repository: widget.repository,
        currentBookId: _bookId,
        currentChapterNum: _chapterNum,
      ),
    );

    if (result != null) {
      setState(() {
        _bookId = result['bookId'];
        _bookName = result['bookName'];
        _chapterNum = result['chapterNum'];
      });
      _loadChapter();
    }
  }

  Future<void> _goToNextChapter() async {
    // Basic logic for now: increment chapter.
    // In a full implementation, we'd check against total chapters
    // and move to the next book if at the end.
    setState(() {
      _chapterNum++;
    });
    _loadChapter();
  }

  Future<void> _goToPreviousChapter() async {
    if (_chapterNum > 1) {
      setState(() {
        _chapterNum--;
      });
      _loadChapter();
    }
  }

  Future<void> _toggleHighlight(String verseNum, String? colorHex) async {
    // If same color, remove highlight
    final finalColor = _highlights[verseNum] == colorHex ? null : colorHex;

    await widget.repository.toggleHighlight(
      _bookId,
      _chapterNum,
      verseNum,
      color: finalColor,
    );

    final newHighlights = await widget.repository.getHighlights(
      _bookId,
      _chapterNum,
    );
    setState(() {
      _highlights = newHighlights;
    });
  }

  void _showHighlightMenu(String verseNum) {
    showCupertinoModalPopup(
      context: context,
      builder: (modalContext) => CupertinoActionSheet(
        title: Text('Versículo $verseNum'),
        actions: [
          _buildColorOption(modalContext, 'Amarillo', '0xFFFFF176', verseNum),
          _buildColorOption(modalContext, 'Verde', '0xFFAED581', verseNum),
          _buildColorOption(modalContext, 'Azul', '0xFF81D4FA', verseNum),
          _buildColorOption(modalContext, 'Rosa', '0xFFF48FB1', verseNum),
          _buildColorOption(modalContext, 'Naranja', '0xFFFFB74D', verseNum),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () =>
              Navigator.of(modalContext, rootNavigator: true).pop(),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  Widget _buildColorOption(
    BuildContext context,
    String label,
    String hex,
    String verseNum,
  ) {
    final color = Color(int.parse(hex));
    final isSelected = _highlights[verseNum] == hex;

    return CupertinoActionSheetAction(
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop();
        _toggleHighlight(verseNum, hex);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: CupertinoColors.separator),
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 17)),
          if (isSelected) ...[
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.check_mark, size: 16),
          ],
        ],
      ),
    );
  }

  void _openSettings() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => ReaderSettingsModal(
        initialFontSize: _fontSize,
        initialLineHeight: _lineHeight,
        initialLetterSpacing: _letterSpacing,
        onSettingsChanged: (fs, lh, ls) {
          setState(() {
            _fontSize = fs;
            _lineHeight = lh;
            _letterSpacing = ls;
          });
          _saveSettings();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        middle: GestureDetector(
          onTap: _openSelector,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_bookName $_chapterNum',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              const Icon(CupertinoIcons.chevron_down, size: 14),
            ],
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _openSettings,
          child: const Icon(CupertinoIcons.ellipsis_circle, size: 22),
        ),
      ),
      child: Stack(
        children: [
          SafeArea(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _error != null
                ? Center(child: Text('Error: $_error'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final double horizontalPadding =
                          constraints.maxWidth > 800
                          ? (constraints.maxWidth - 700) / 2
                          : 24.0;

                      return ListView(
                        padding: EdgeInsets.only(
                          left: horizontalPadding,
                          right: horizontalPadding,
                          top: 40,
                          bottom: 60,
                        ),
                        children: [
                          ..._buildVerses(),
                          if (_footnotes != null && _footnotes!.isNotEmpty) ...[
                            const SizedBox(height: 48),
                            const Divider(color: CupertinoColors.separator),
                            const SizedBox(height: 24),
                            const Text(
                              'Notas al pie',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._buildFootnotes(),
                          ],
                        ],
                      );
                    },
                  ),
          ),
          if (!_isLoading) ...[
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _chapterNum > 1
                    ? _buildNavArrow(
                        CupertinoIcons.left_chevron,
                        _goToPreviousChapter,
                      )
                    : const SizedBox(width: 44),
              ),
            ),
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavArrow(
                  CupertinoIcons.right_chevron,
                  _goToNextChapter,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavArrow(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.withOpacity(0.7),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Icon(icon, size: 20, color: CupertinoColors.systemGrey),
      ),
    );
  }

  List<Widget> _buildVerses() {
    final sortedKeys = _verses!.keys.toList()..sort(_compareKeys);

    return [
      Wrap(
        spacing: 0,
        runSpacing: 8,
        children: sortedKeys.map((key) {
          final highlightHex = _highlights[key];
          final highlightColor = highlightHex != null
              ? Color(int.parse(highlightHex))
              : null;

          return GestureDetector(
            onLongPress: () => _showHighlightMenu(key),
            onTap: () => _showHighlightMenu(key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: highlightColor?.withOpacity(0.35),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    WidgetSpan(
                      child: Transform.translate(
                        offset: const Offset(0, -6),
                        child: Text(
                          '$key ',
                          style: TextStyle(
                            fontSize: _fontSize * 0.6,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ),
                    ),
                    TextSpan(
                      text: '${_verses![key]} ',
                      style: TextStyle(
                        fontSize: _fontSize,
                        height: _lineHeight,
                        letterSpacing: _letterSpacing,
                        color: CupertinoColors.label,
                        fontFamily: 'Georgia',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ];
  }

  List<Widget> _buildFootnotes() {
    final sortedKeys = _footnotes!.keys.toList()..sort(_compareKeys);
    return sortedKeys.map((key) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          '$key: ${_footnotes![key]}',
          style: const TextStyle(
            fontSize: 15,
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
    if (aNum != null && bNum != null) return aNum.compareTo(bNum);
    return a.compareTo(b);
  }
}
