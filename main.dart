import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

void main() {
  runApp(const BibleTranscriptionApp());
}

class BibleTranscriptionApp extends StatelessWidget {
  const BibleTranscriptionApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '성경 필사',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFFF5E6D3),
      ),
      home: const StartScreen(),
    );
  }
}

// 성경 데이터 모델
class BibleData {
  final String translation;
  final List<Book> books;

  BibleData({required this.translation, required this.books});

  factory BibleData.fromJson(Map<String, dynamic> json) {
    return BibleData(
      translation: json['translation'] ?? '',
      books: (json['books'] as List)
          .map((book) => Book.fromJson(book))
          .toList(),
    );
  }
}

class Book {
  final String name;
  final String abbr;
  final String testament;
  final int order;
  final List<Chapter> chapters;

  Book({
    required this.name,
    required this.abbr,
    required this.testament,
    required this.order,
    required this.chapters,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      name: json['name'] ?? '',
      abbr: json['abbr'] ?? '',
      testament: json['testament'] ?? '',
      order: json['order'] ?? 0,
      chapters: (json['chapters'] as List)
          .map((chapter) => Chapter.fromJson(chapter))
          .toList(),
    );
  }
}

class Chapter {
  final int chapter;
  final List<Verse> verses;

  Chapter({required this.chapter, required this.verses});

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      chapter: json['chapter'] ?? 0,
      verses: (json['verses'] as List)
          .map((verse) => Verse.fromJson(verse))
          .toList(),
    );
  }
}

class Verse {
  final int verse;
  final String text;

  Verse({required this.verse, required this.text});

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(verse: json['verse'] ?? 0, text: json['text'] ?? '');
  }
}

// Section 1: 시작 화면
class StartScreen extends StatelessWidget {
  const StartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('성경'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SelectionScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4B896),
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            '시작하기',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

// Section 2: 성경 선택 화면
class SelectionScreen extends StatefulWidget {
  const SelectionScreen({Key? key}) : super(key: key);

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  String? selectedBook;
  int? selectedChapter;
  int? selectedStartVerse;
  int? selectedEndVerse;
  BibleData? bibleData;
  bool isLoading = true;

  List<String> availableBooks = [];
  List<int> availableChapters = [];
  List<int> availableVerses = [];

  @override
  void initState() {
    super.initState();
    _loadBibleData();
  }

  Future<void> _loadBibleData() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/converted_bible.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final bible = BibleData.fromJson(jsonData['bible']);

      setState(() {
        bibleData = bible;
        availableBooks = bible.books.map((book) => book.name).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('성경 데이터를 불러오는데 실패했습니다: $e')));
      }
    }
  }

  void _updateChapters(String bookName) {
    final book = bibleData?.books.firstWhere((b) => b.name == bookName);
    if (book != null) {
      setState(() {
        availableChapters = book.chapters.map((c) => c.chapter).toList();
        selectedChapter = null;
        selectedStartVerse = null;
        selectedEndVerse = null;
        availableVerses = [];
      });
    }
  }

  void _updateVerses(String bookName, int chapterNum) {
    final book = bibleData?.books.firstWhere((b) => b.name == bookName);
    final chapter = book?.chapters.firstWhere((c) => c.chapter == chapterNum);
    if (chapter != null) {
      setState(() {
        availableVerses = chapter.verses.map((v) => v.verse).toList();
        selectedStartVerse = null;
        selectedEndVerse = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('성경'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '원하시는\n구절을 설정 하세요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            DropdownSection(
              label: '성경책',
              hint: '선택하세요',
              value: selectedBook,
              items: availableBooks,
              onChanged: (value) {
                setState(() => selectedBook = value);
                if (value != null) _updateChapters(value);
              },
            ),
            DropdownSectionInt(
              label: '몇번째장',
              hint: '장 선택',
              value: selectedChapter,
              items: availableChapters,
              onChanged: (value) {
                setState(() => selectedChapter = value);
                if (value != null && selectedBook != null) {
                  _updateVerses(selectedBook!, value);
                }
              },
            ),
            DropdownSectionInt(
              label: '몇절부터',
              hint: '시작 절',
              value: selectedStartVerse,
              items: availableVerses,
              onChanged: (value) => setState(() => selectedStartVerse = value),
            ),
            DropdownSectionInt(
              label: '몇절까지',
              hint: '끝 절',
              value: selectedEndVerse,
              items: availableVerses,
              onChanged: (value) => setState(() => selectedEndVerse = value),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedBook != null &&
                      selectedChapter != null &&
                      selectedStartVerse != null &&
                      selectedEndVerse != null &&
                      bibleData != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TranscriptionScreen(
                          bibleData: bibleData!,
                          book: selectedBook!,
                          chapter: selectedChapter!,
                          startVerse: selectedStartVerse!,
                          endVerse: selectedEndVerse!,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('모든 항목을 선택해주세요')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4B896),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '시작하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DropdownSection extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const DropdownSection({
    Key? key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                hint: Text(hint),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DropdownSectionInt extends StatelessWidget {
  final String label;
  final String hint;
  final int? value;
  final List<int> items;
  final ValueChanged<int?> onChanged;

  const DropdownSectionInt({
    Key? key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: value,
                hint: Text(hint),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: items.map((int item) {
                  return DropdownMenuItem<int>(
                    value: item,
                    child: Text('$item'),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Section 3: 필사 화면
class TranscriptionScreen extends StatefulWidget {
  final BibleData bibleData;
  final String book;
  final int chapter;
  final int startVerse;
  final int endVerse;

  const TranscriptionScreen({
    Key? key,
    required this.bibleData,
    required this.book,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
  }) : super(key: key);

  @override
  State<TranscriptionScreen> createState() => _TranscriptionScreenState();
}

class _TranscriptionScreenState extends State<TranscriptionScreen> {
  final TextEditingController _controller = TextEditingController();
  String _displayText = '';

  @override
  void initState() {
    super.initState();
    _loadVerses();
  }

  void _loadVerses() {
    try {
      // 선택된 책 찾기
      final book = widget.bibleData.books.firstWhere(
        (b) => b.name == widget.book,
      );

      // 선택된 장 찾기
      final chapter = book.chapters.firstWhere(
        (c) => c.chapter == widget.chapter,
      );

      // 선택된 범위의 구절들 필터링
      final verses = chapter.verses.where((v) {
        return v.verse >= widget.startVerse && v.verse <= widget.endVerse;
      }).toList();

      // 표시할 텍스트 생성
      String displayText = '';
      for (var verse in verses) {
        displayText += '${verse.verse}. ${verse.text}\n\n';
      }

      setState(() {
        _displayText = displayText.trim();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('구절을 불러오는데 실패했습니다: $e')));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.book} ${widget.chapter}:${widget.startVerse}-${widget.endVerse}',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // 성경 구절 표시 영역 (상단)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 2),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                _displayText,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.8,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          // 필사 입력 영역 (중간)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                maxLines: null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '위의 성경 구절을 필사하세요...',
                ),
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ),
          // 키보드 (하단)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                // 특수 문자 행
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKeyboardButton('ㅋㅋㅋ'),
                      _buildKeyboardButton('ㅂㄷ'),
                      _buildKeyboardButton('ㅏㅓ'),
                      _buildKeyboardButton('표'),
                      _buildKeyboardButton('점'),
                      _buildKeyboardButton('—'),
                      _buildKeyboardButton('송'),
                    ],
                  ),
                ),
                // 키보드 행들
                _buildKeyRow([
                  'ㅂ',
                  'ㅈ',
                  'ㄷ',
                  'ㄱ',
                  'ㅅ',
                  'ㅛ',
                  'ㅕ',
                  'ㅑ',
                  'ㅐ',
                  'ㅔ',
                ]),
                _buildKeyRow(['ㅁ', 'ㄴ', 'ㅇ', 'ㄹ', 'ㅎ', 'ㅗ', 'ㅓ', 'ㅏ', 'ㅣ']),
                Row(
                  children: [
                    _buildSpecialKey('⇧', flex: 2),
                    ...'ㅋㅌㅊㅍㅠㅜㅡ'
                        .split('')
                        .map((k) => Expanded(child: _buildKeyboardButton(k))),
                    _buildSpecialKey('⌫', flex: 2),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      _buildSpecialKey('123', flex: 2),
                      _buildSpecialKey('😊', flex: 2),
                      Expanded(
                        flex: 8,
                        child: _buildKeyboardButton('스페이스', isLarge: true),
                      ),
                      _buildSpecialKey(
                        '입력',
                        flex: 2,
                        color: Colors.blue.shade100,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: keys
            .map((key) => Expanded(child: _buildKeyboardButton(key)))
            .toList(),
      ),
    );
  }

  Widget _buildKeyboardButton(String text, {bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () {
            if (text == '스페이스') {
              _controller.text += ' ';
            } else if (text != '⇧' &&
                text != '⌫' &&
                text != '123' &&
                text != '😊' &&
                text != '입력') {
              _controller.text += text;
            }
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: isLarge ? 12 : 16,
              horizontal: 8,
            ),
            alignment: Alignment.center,
            child: Text(text, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey(String text, {int flex = 1, Color? color}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: color ?? Colors.grey.shade300,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: () {
              if (text == '⌫' && _controller.text.isNotEmpty) {
                _controller.text = _controller.text.substring(
                  0,
                  _controller.text.length - 1,
                );
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length),
                );
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
