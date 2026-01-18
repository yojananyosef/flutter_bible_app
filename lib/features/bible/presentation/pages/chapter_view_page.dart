import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import '../../domain/repositories/bible_repository.dart';
import '../widgets/selection_modal.dart';
import '../widgets/reader_settings_modal.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/entities/book_entity.dart';

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
  double _lineHeight = 1.6;
  double _letterSpacing = 0.02;
  String _theme = 'light';

  // TTS & Scrolling
  final FlutterTts _flutterTts = FlutterTts();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _verseKeysMap = {};
  bool _isSpeaking = false;
  bool _isPaused = false;
  int _currentVerseIndex = -1;
  List<String> _verseKeys = [];

  @override
  void initState() {
    super.initState();
    _bookId = widget.initialBookId;
    _bookName = widget.initialBookName;
    _chapterNum = widget.initialChapterNum;
    _initTts();
    _loadChapter();
    _loadSettings();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      if (_isSpeaking && !_isPaused) {
        _readNextVerse();
      }
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _isPaused = false;
          _currentVerseIndex = -1;
        });
      }
    });
  }

  Future<void> _loadSettings() async {
    final settings = await widget.repository.getReaderSettings();
    if (settings != null && mounted) {
      setState(() {
        _fontSize = (settings['fontSize'] as num?)?.toDouble() ?? 18.0;
        _lineHeight = (settings['lineHeight'] as num?)?.toDouble() ?? 1.6;
        _letterSpacing =
            (settings['letterSpacing'] as num?)?.toDouble() ?? 0.02;
        _theme = (settings['theme'] as String?) ?? 'light';
      });
    }
  }

  Future<void> _saveSettings() async {
    await widget.repository.saveReaderSettings({
      'fontSize': _fontSize,
      'lineHeight': _lineHeight,
      'letterSpacing': _letterSpacing,
      'theme': _theme,
    });
  }

  Future<void> _loadChapter() async {
    _stopReading();
    if (mounted) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        widget.repository.getChapter(_bookId, _chapterNum),
        widget.repository.getFootnotes(_bookId, _chapterNum),
        widget.repository.getHighlights(_bookId, _chapterNum),
      ]);

      await widget.repository.saveLastRead(_bookId, _bookName, _chapterNum);

      if (mounted) {
        setState(() {
          _verses = results[0] as Map<String, String>?;
          _footnotes = results[1] as Map<String, String>?;
          _highlights = Map<String, String>.from(results[2] as Map);
          _verseKeys = _verses != null
              ? (_verses!.keys.toList()..sort(_compareKeys))
              : [];
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

    if (result != null && mounted) {
      setState(() {
        _bookId = result['bookId'];
        _bookName = result['bookName'];
        _chapterNum = result['chapterNum'];
      });
      _loadChapter();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _goToNextChapter({bool autoPlay = false}) async {
    final booksMap = await widget.repository.getBooks();
    final List<BookEntity> allBooks = booksMap.values
        .expand((list) => list)
        .toList();
    final currentBookIndex = allBooks.indexWhere((b) => b.id == _bookId);
    if (currentBookIndex == -1) return;
    final BookEntity currentBook = allBooks[currentBookIndex];

    if (_chapterNum < currentBook.capitulos) {
      if (mounted) setState(() => _chapterNum++);
    } else if (currentBookIndex < allBooks.length - 1) {
      final BookEntity nextBook = allBooks[currentBookIndex + 1];
      if (mounted) {
        setState(() {
          _bookId = nextBook.id;
          _bookName = nextBook.nombre;
          _chapterNum = 1;
        });
      }
    } else {
      return;
    }
    await _loadChapter();
    if (autoPlay) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _speakChapter();
      });
    }
  }

  Future<void> _goToPreviousChapter() async {
    if (_chapterNum > 1) {
      if (mounted) setState(() => _chapterNum--);
      await _loadChapter();
    } else {
      final booksMap = await widget.repository.getBooks();
      final List<BookEntity> allBooks = booksMap.values
          .expand((list) => list)
          .toList();
      final currentBookIndex = allBooks.indexWhere((b) => b.id == _bookId);
      if (currentBookIndex > 0) {
        final BookEntity prevBook = allBooks[currentBookIndex - 1];
        if (mounted) {
          setState(() {
            _bookId = prevBook.id;
            _bookName = prevBook.nombre;
            _chapterNum = prevBook.capitulos;
          });
        }
        await _loadChapter();
      }
    }
  }

  Future<void> _toggleHighlight(String verseNum, String? colorHex) async {
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
    if (mounted) setState(() => _highlights = newHighlights);
  }

  Future<void> _speakChapter() async {
    if (_verses == null || _verses!.isEmpty) return;
    if (_isSpeaking) {
      if (_isPaused) {
        if (mounted) setState(() => _isPaused = false);
        _readCurrentVerse();
      } else {
        await _flutterTts.stop();
        if (mounted) setState(() => _isPaused = true);
      }
      return;
    }
    if (mounted) {
      setState(() {
        _isSpeaking = true;
        _isPaused = false;
        _currentVerseIndex = 0;
      });
    }
    _readCurrentVerse();
  }

  Future<void> _readCurrentVerse() async {
    if (_currentVerseIndex < 0 || _currentVerseIndex >= _verseKeys.length) {
      final wasSpeaking = _isSpeaking && !_isPaused;
      _stopReading();
      if (wasSpeaking) _goToNextChapter(autoPlay: true);
      return;
    }
    final key = _verseKeys[_currentVerseIndex];
    final text = _verses![key] ?? '';
    String prefix = _currentVerseIndex == 0
        ? '$_bookName, capítulo $_chapterNum. '
        : '';
    if (mounted) setState(() => _isSpeaking = true);
    await _flutterTts.speak('$prefix$text');
    _scrollToCurrentVerse();
  }

  void _scrollToCurrentVerse() {
    if (_currentVerseIndex < 0 || _currentVerseIndex >= _verseKeys.length)
      return;
    final key = _verseKeys[_currentVerseIndex];
    final globalKey = _verseKeysMap[key];
    if (globalKey == null) return;
    final ctx = globalKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      alignment: 0.3,
    );
  }

  void _readNextVerse() {
    if (mounted) {
      _currentVerseIndex++;
      _readCurrentVerse();
    }
  }

  void _stopReading() {
    _flutterTts.stop();
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
        _currentVerseIndex = -1;
      });
    }
  }

  @override
  void dispose() {
    _stopReading();
    _scrollController.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (_theme) {
      case 'dark':
        return const Color(0xFF1A1A1A);
      case 'sepia':
        return const Color(0xFFF5F5F0);
      default:
        return CupertinoColors.white;
    }
  }

  Color get _textColor {
    switch (_theme) {
      case 'dark':
        return const Color(0xFFE8E8E8);
      case 'sepia':
        return const Color(0xFF1A1A18);
      default:
        return const Color(0xFF1A1A18);
    }
  }

  void _openSettings() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => ReaderSettingsModal(
        initialFontSize: _fontSize,
        initialLineHeight: _lineHeight,
        initialLetterSpacing: _letterSpacing,
        initialTheme: _theme,
        onSettingsChanged: (fs, lh, ls) {
          if (mounted)
            setState(() {
              _fontSize = fs;
              _lineHeight = lh;
              _letterSpacing = ls;
            });
          _saveSettings();
        },
        onThemeChanged: (theme) {
          if (mounted) setState(() => _theme = theme);
          _saveSettings();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: _bgColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: _bgColor.withOpacity(0.9),
        middle: GestureDetector(
          onTap: _openSelector,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_bookName $_chapterNum',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
              const SizedBox(width: 4),
              Icon(CupertinoIcons.chevron_down, size: 14, color: _textColor),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _speakChapter,
              onLongPress: _stopReading,
              child: Icon(
                _isSpeaking
                    ? (_isPaused
                          ? CupertinoIcons.play_circle
                          : CupertinoIcons.pause_circle)
                    : CupertinoIcons.speaker_2,
                size: 22,
                color: _isSpeaking ? CupertinoColors.activeBlue : _textColor,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _openSettings,
              child: Icon(
                CupertinoIcons.ellipsis_circle,
                size: 22,
                color: _textColor,
              ),
            ),
          ],
        ),
      ),
      child: Stack(
        children: [
          SafeArea(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      'Error: $_error',
                      style: TextStyle(color: _textColor),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final double effectiveMaxWidth = _fontSize * 35;
                      final double horizontalPadding =
                          constraints.maxWidth > effectiveMaxWidth
                          ? (constraints.maxWidth - effectiveMaxWidth) / 2
                          : 24.0;
                      return ListView(
                        controller: _scrollController,
                        padding: EdgeInsets.only(
                          left: horizontalPadding,
                          right: horizontalPadding,
                          top: 40,
                          bottom: MediaQuery.of(context).size.height * 0.4,
                        ),
                        children: [
                          ..._buildVerses(),
                          if (_footnotes != null && _footnotes!.isNotEmpty) ...[
                            const SizedBox(height: 48),
                            Divider(color: _textColor.withOpacity(0.2)),
                            const SizedBox(height: 24),
                            Text(
                              'Notas al pie',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _textColor,
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
                child: (_bookId != 'GEN' || _chapterNum > 1)
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
    return _AnimatedNavButton(
      icon: icon,
      onPressed: onPressed,
      themeColor: _textColor,
    );
  }

  List<Widget> _buildVerses() {
    if (_verses == null) return [];
    final sortedKeys = _verses!.keys.toList()..sort(_compareKeys);
    return [
      Wrap(
        spacing: 0,
        runSpacing: 12,
        children: sortedKeys.map((key) {
          final highlightHex = _highlights[key];
          final highlightColor = highlightHex != null
              ? Color(int.parse(highlightHex))
              : null;
          final isReading =
              _isSpeaking &&
              _currentVerseIndex != -1 &&
              _verseKeys[_currentVerseIndex] == key;
          _verseKeysMap[key] ??= GlobalKey();
          return GestureDetector(
            key: _verseKeysMap[key],
            onLongPress: () => _showHighlightMenu(key),
            onTap: () => _showHighlightMenu(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: isReading
                    ? CupertinoColors.activeBlue.withOpacity(0.12)
                    : highlightColor?.withOpacity(0.35),
                borderRadius: BorderRadius.circular(4),
                border: isReading
                    ? Border.all(
                        color: CupertinoColors.activeBlue.withOpacity(0.3),
                        width: 1,
                      )
                    : null,
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
                            fontWeight: isReading
                                ? FontWeight.w900
                                : FontWeight.bold,
                            color: isReading
                                ? CupertinoColors.activeBlue
                                : _textColor.withOpacity(0.6),
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
                        color: isReading
                            ? CupertinoColors.activeBlue
                            : _textColor,
                        fontWeight: isReading ? FontWeight.w500 : null,
                        fontFamily: 'serif',
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
    if (_footnotes == null) return [];
    final sortedKeys = _footnotes!.keys.toList()..sort(_compareKeys);
    return sortedKeys.map((key) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          '$key: ${_footnotes![key]}',
          style: TextStyle(
            fontSize: 15,
            color: _textColor.withOpacity(0.7),
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
}

class _AnimatedNavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color themeColor;
  const _AnimatedNavButton({
    required this.icon,
    required this.onPressed,
    required this.themeColor,
  });
  @override
  State<_AnimatedNavButton> createState() => _AnimatedNavButtonState();
}

class _AnimatedNavButtonState extends State<_AnimatedNavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedScale(
          scale: _isHovered && _controller.isDismissed ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isHovered
                    ? widget.themeColor.withOpacity(0.1)
                    : CupertinoColors.systemBackground.withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(
                      _isHovered ? 0.08 : 0.04,
                    ),
                    blurRadius: _isHovered ? 12 : 6,
                    offset: Offset(0, _isHovered ? 4 : 2),
                  ),
                ],
                border: Border.all(
                  color: widget.themeColor.withOpacity(0.15),
                  width: 0.5,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 20,
                color: _isHovered
                    ? CupertinoColors.activeBlue
                    : widget.themeColor.withOpacity(0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
