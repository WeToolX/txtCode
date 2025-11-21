import 'dart:io';
import 'dart:math';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const TxtCodeApp());
}

class TxtCodeApp extends StatelessWidget {
  const TxtCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '文本扰动工具',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        visualDensity: VisualDensity.compact,
        textTheme: ThemeData().textTheme.apply(
          // fontSizeFactor: 0.95,
          bodyColor: Colors.black87,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
      home: const TextProcessorPage(),
    );
  }
}

enum EmojiPlatform { wx, qq, mo, universal }

enum DigitStyle { fullWidth, whiteCircle, blackCircle, mini, bracketed }

enum ZeroWidthType {
  zeroWidthSpace,
  zeroWidthNonJoiner,
  zeroWidthJoiner,
  wordJoiner,
}

class TextProcessorPage extends StatefulWidget {
  const TextProcessorPage({super.key});

  @override
  State<TextProcessorPage> createState() => _TextProcessorPageState();
}

class _TextProcessorPageState extends State<TextProcessorPage> {
  static const double _cardPadding = 10;
  static const double _gap = 8;

  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final TextEditingController _filePathController = TextEditingController(
    text: 'output.txt',
  );
  final TextEditingController _zeroWidthMinController = TextEditingController(
    text: '0',
  );
  final TextEditingController _zeroWidthMaxController = TextEditingController(
    text: '2',
  );

  final Random _random = Random();

  bool _enableEmoji = true;
  EmojiPlatform _emojiPlatform = EmojiPlatform.universal;
  double _emojiProbability = 0.1;

  bool _enableDigitMapping = false;
  DigitStyle _digitStyle = DigitStyle.fullWidth;

  bool _enableZeroWidth = false;
  ZeroWidthType _zeroWidthType = ZeroWidthType.zeroWidthSpace;

  bool _showZeroWidthMarkers = false;

  int _originalLength = 0;
  int _convertedLength = 0;
  int _zeroWidthCount = 0;
  String _lastConverted = '';

  final Map<EmojiPlatform, List<String>> _emojiPacks = {
    EmojiPlatform.wx: ['😀', '😁', '😊', '🤔', '😎', '😘', '🥳', '👍','😆','😅','😉','😢','😭','😡','😴','😱',
    '🤤','🤮','😷','🤒','🤕','🤧','🤨','🥰',
    '😋','😜','🤪','🤫','🤭','😇','🤡','👻'],
    EmojiPlatform.qq: [
      '(萌)',
      '(笑)',
      '(OK)',
      '(抱抱)',
      '(加油)',
      '(玫瑰)',
      '(期待)',
      '(鼓掌)',
      '(微笑)','(害羞)','(尴尬)','(跳跳)','(流泪)','(晕)','(酷)','(抓狂)',
    '(吐舌)','(惊讶)','(敲打)','(转圈)','(困)','(大兵)','(菜刀)','(叹气)',
    '(棒棒)','(红包)','(胜利)','(爱心)','(心碎)','(疑问)','(强)','(弱)',
    ],
    EmojiPlatform.mo: ['🛰️', '🌙', '✨', '🚀', '🛰️', '⚙️', '🧭', '📡'],
    EmojiPlatform.universal: ['😄', '😂', '😉', '🤩', '🙌', '🔥', '🎉', '👏'],
  };

  final Map<DigitStyle, List<String>> _digitStyles = {
    DigitStyle.fullWidth: '０１２３４５６７８９'.split(''),
    DigitStyle.whiteCircle: ['⓪', '①', '②', '③', '④', '⑤', '⑥', '⑦', '⑧', '⑨'],
    DigitStyle.blackCircle: ['⓿', '❶', '❷', '❸', '❹', '❺', '❻', '❼', '❽', '❾'],
    DigitStyle.mini: ['⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹'],
    DigitStyle.bracketed: [
      '（0）',
      '（1）',
      '（2）',
      '（3）',
      '（4）',
      '（5）',
      '（6）',
      '（7）',
      '（8）',
      '（9）',
    ],
  };

    final Map<ZeroWidthType, String> _zeroWidthChars = const {
    ZeroWidthType.zeroWidthSpace: '\u200b',
    ZeroWidthType.zeroWidthNonJoiner: '\u200c',
    ZeroWidthType.zeroWidthJoiner: '\u200d',
    ZeroWidthType.leftToRightMark: '\u200e',
    ZeroWidthType.rightToLeftMark: '\u200f',
    ZeroWidthType.wordJoiner: '\u2060',
    ZeroWidthType.functionApplication: '\u2061',
    ZeroWidthType.invisibleSeparator: '\u2063',
  };

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    _filePathController.dispose();
    _zeroWidthMinController.dispose();
    _zeroWidthMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 44,
        title: const Text(
          '文本扰动',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            const horizontalPadding = 16.0;
            final spacing = isWide ? 12.0 : 8.0;
            final contentWidth = constraints.maxWidth - horizontalPadding * 2;
            final cardWidth = isWide
                ? (contentWidth - spacing) / 2
                : contentWidth;
            final sections = _buildSections(cardWidth);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(horizontalPadding),
              child: Wrap(
                alignment: WrapAlignment.start,
                spacing: spacing,
                runSpacing: spacing,
                children: sections,
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildSections(double width) {
    return [
      SizedBox(width: width, child: _buildInputCard()),
      SizedBox(width: width, child: _buildEmojiCard()),
      SizedBox(width: width, child: _buildDigitCard()),
      SizedBox(width: width, child: _buildZeroWidthCard()),
      SizedBox(width: width, child: _buildDebugToggle()),
      SizedBox(width: width, child: _buildFileOpsCard()),
      SizedBox(width: width, child: _buildOutputCard()),
      SizedBox(width: width, child: _buildStatsRow()),
    ];
  }

  Widget _buildInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('原始文本', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: _gap),
            TextField(
              controller: _inputController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '输入待处理文本',
              ),
            ),
            const SizedBox(height: _gap),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste),
                  label: const Text('粘贴板输入'),
                  style: _compactButtonStyle(context),
                ),
                OutlinedButton.icon(
                  onPressed: _clearInput,
                  icon: const Icon(Icons.clear),
                  label: const Text('清空输入'),
                  style: _compactOutlinedStyle(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('是否添加表情包'),
              value: _enableEmoji,
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              onChanged: (value) => setState(() => _enableEmoji = value),
            ),
            if (_enableEmoji) ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<EmojiPlatform>(
                      decoration: const InputDecoration(
                        labelText: '表情包平台',
                        border: OutlineInputBorder(),
                      ),
                      value: _emojiPlatform,
                      items: EmojiPlatform.values
                          .map(
                            (platform) => DropdownMenuItem(
                              value: platform,
                              child: Text(_platformLabel(platform)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _emojiPlatform = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('插入概率'),
                            Text(
                              '${(_emojiProbability * 100).toStringAsFixed(0)}%',
                            ),
                          ],
                        ),
                        Slider(
                          value: _emojiProbability,
                          max: 0.5,
                          divisions: 50,
                          label:
                              '${(_emojiProbability * 100).toStringAsFixed(0)}%',
                          onChanged: (value) =>
                              setState(() => _emojiProbability = value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDigitCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('是否映射数字'),
              value: _enableDigitMapping,
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              onChanged: (value) => setState(() => _enableDigitMapping = value),
            ),
            if (_enableDigitMapping)
              DropdownButtonFormField<DigitStyle>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '数字样式',
                ),
                value: _digitStyle,
                items: DigitStyle.values
                    .map(
                      (style) => DropdownMenuItem(
                        value: style,
                        child: Text(_digitStyleLabel(style)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _digitStyle = value);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildZeroWidthCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('是否插入0宽字符'),
              value: _enableZeroWidth,
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              onChanged: (value) => setState(() => _enableZeroWidth = value),
            ),
            if (_enableZeroWidth) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _zeroWidthMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '随机最小值',
                        hintText: '最小插入数量',
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _zeroWidthMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '随机最大值',
                        hintText: '最大插入数量',
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _gap),
              DropdownButtonFormField<ZeroWidthType>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '0宽类型',
                ),
                value: _zeroWidthType,
                items: ZeroWidthType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_zeroWidthLabel(type)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _zeroWidthType = value);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDebugToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _cardPadding),
        child: CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('查看原始文本 (调试)'),
          value: _showZeroWidthMarkers,
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          onChanged: (value) {
            setState(() {
              _showZeroWidthMarkers = value ?? false;
              _refreshOutputController();
            });
          },
        ),
      ),
    );
  }

  Widget _buildFileOpsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('操作区', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: _gap),
            TextField(
              controller: _filePathController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '文件路径',
                hintText: '用于加载/保存文本的文件路径',
              ),
            ),
            const SizedBox(height: _gap),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadFromFile,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('从文件加载文本'),
                  style: _compactButtonStyle(context),
                ),
                ElevatedButton.icon(
                  onPressed: _saveToFile,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('结果保存到文本'),
                  style: _compactButtonStyle(context),
                ),
                ElevatedButton.icon(
                  onPressed: _executeConversion,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('执行转换'),
                  style: _compactButtonStyle(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('输出结果 (可编辑)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: _gap),
            TextField(
              controller: _outputController,
              minLines: 5,
              maxLines: 8,
              readOnly: _showZeroWidthMarkers,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '转换后的文本会显示在这里',
              ),
              onChanged: (value) {
                if (!_showZeroWidthMarkers) {
                  _lastConverted = value;
                  _convertedLength = value.characters.length;
                  _zeroWidthCount = _countZeroWidth(value);
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: _gap),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _copyResult,
                icon: const Icon(Icons.copy),
                label: const Text('复制结果到剪切板'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 14),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '原始长度: $_originalLength    转换后长度: $_convertedLength    0宽数量: $_zeroWidthCount',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            IconButton(
              tooltip: '重新执行转换',
              onPressed: _executeConversion,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _inputController.text = data!.text!;
      _showSnack('已粘贴剪贴板内容');
    }
  }

  void _clearInput() {
    _inputController.clear();
  }

  Future<void> _loadFromFile() async {
    final path = _filePathController.text.trim();
    if (path.isEmpty) {
      _showSnack('请先填写文件路径');
      return;
    }
    try {
      final file = File(path);
      final content = await file.readAsString();
      if (!mounted) return;
      setState(() {
        _inputController.text = content;
      });
      _showSnack('已加载文件内容');
    } catch (e) {
      _showSnack('读取失败: $e');
    }
  }

  Future<void> _saveToFile() async {
    final path = _filePathController.text.trim();
    if (path.isEmpty) {
      _showSnack('请先填写文件路径');
      return;
    }
    final data = _lastConverted.isNotEmpty
        ? _lastConverted
        : _outputController.text;
    try {
      final file = File(path);
      await file.writeAsString(data);
      _showSnack('结果已写入 $path');
    } catch (e) {
      _showSnack('写入失败: $e');
    }
  }

  void _executeConversion() {
    String result = _inputController.text;
    _originalLength = result.characters.length;

    if (_enableEmoji) {
      result = _insertEmojis(result);
    }
    if (_enableDigitMapping) {
      result = _mapDigits(result);
    }
    if (_enableZeroWidth) {
      final minCount = _parseInt(_zeroWidthMinController.text, fallback: 0);
      final maxCount = _parseInt(
        _zeroWidthMaxController.text,
        fallback: minCount,
      );
      final low = min(minCount, maxCount);
      final high = max(minCount, maxCount);
      result = _insertZeroWidth(result, low, high);
    }

    _lastConverted = result;
    _convertedLength = result.characters.length;
    _zeroWidthCount = _countZeroWidth(result);
    _refreshOutputController();
    setState(() {});
  }

  String _insertEmojis(String input) {
    final emojis = _emojiPacks[_emojiPlatform] ?? [];
    if (emojis.isEmpty || _emojiProbability <= 0) {
      return input;
    }
    final buffer = StringBuffer();
    for (final char in input.characters) {
      buffer.write(char);
      if (_random.nextDouble() < _emojiProbability) {
        buffer.write(emojis[_random.nextInt(emojis.length)]);
      }
    }
    return buffer.toString();
  }

  String _mapDigits(String input) {
    final mapping = _digitStyles[_digitStyle]!;
    return input.replaceAllMapped(RegExp(r'\d'), (match) {
      final index = int.parse(match.group(0)!);
      return mapping[index];
    });
  }

  String _insertZeroWidth(String input, int minCount, int maxCount) {
    final zeroWidthChar = _zeroWidthChars[_zeroWidthType] ?? '';
    if (zeroWidthChar.isEmpty || maxCount <= 0) {
      return input;
    }
    final buffer = StringBuffer();
    for (final char in input.characters) {
      buffer.write(char);
      final insertCount = minCount == maxCount
          ? minCount
          : _random.nextInt(maxCount - minCount + 1) + minCount;
      if (insertCount > 0) {
        buffer.write(List.filled(insertCount, zeroWidthChar).join());
      }
    }
    return buffer.toString();
  }

  void _refreshOutputController() {
    final displayText = _showZeroWidthMarkers
        ? _markZeroWidth(_lastConverted)
        : _lastConverted;
    _outputController
      ..text = displayText
      ..selection = TextSelection.collapsed(offset: displayText.length);
  }

  int _parseInt(String value, {required int fallback}) {
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 0) {
      return fallback;
    }
    return parsed;
  }

  int _countZeroWidth(String text) {
    final reg = RegExp('[\\u200b\\u200c\\u200d\\u200e\\u200f\\u2060\\u2061\\u2063]');
    return reg.allMatches(text).length;
  }

  String _markZeroWidth(String text) {
    final reg = RegExp('[\\u200b\\u200c\\u200d\\u200e\\u200f\\u2060\\u2061\\u2063]');
    return text.replaceAll(reg, '[0宽字符]');
  }

  String _platformLabel(EmojiPlatform platform) {
    switch (platform) {
      case EmojiPlatform.wx:
        return 'wx';
      case EmojiPlatform.qq:
        return 'qq';
      case EmojiPlatform.mo:
        return 'mo通用';
      case EmojiPlatform.universal:
        return '通用';
    }
  }

  String _digitStyleLabel(DigitStyle style) {
    switch (style) {
      case DigitStyle.fullWidth:
        return '全角数字';
      case DigitStyle.whiteCircle:
        return '白底带圆数字';
      case DigitStyle.blackCircle:
        return '黑底带圈数字';
      case DigitStyle.mini:
        return '迷你数字';
      case DigitStyle.bracketed:
        return '括号数字';
    }
  }

  String _zeroWidthLabel(ZeroWidthType type) {
    switch (type) {
      case ZeroWidthType.zeroWidthSpace:
        return '0宽空格 (\\u200B)';
      case ZeroWidthType.zeroWidthNonJoiner:
        return '0宽非连接符 (\\u200C)';
      case ZeroWidthType.zeroWidthJoiner:
        return '0宽连接符 (\\u200D)';
      case ZeroWidthType.leftToRightMark:
        return '左至右标记 (\\u200E)';
      case ZeroWidthType.rightToLeftMark:
        return '右至左标记 (\\u200F)';
      case ZeroWidthType.wordJoiner:
        return '单词连接 (\\u2060)';
      case ZeroWidthType.functionApplication:
        return '函数应用 (\\u2061)';
      case ZeroWidthType.invisibleSeparator:
        return '隐形分隔 (\\u2063)';
    }
  }

  ButtonStyle _compactButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      minimumSize: const Size(0, 38),
      textStyle: const TextStyle(fontSize: 14),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  ButtonStyle _compactOutlinedStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      minimumSize: const Size(0, 38),
      textStyle: const TextStyle(fontSize: 14),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: Theme.of(context).colorScheme.outline),
    );
  }

  void _copyResult() {
    final data = _lastConverted.isNotEmpty
        ? _lastConverted
        : _outputController.text;
    if (data.isEmpty) {
      _showSnack('没有可复制的内容');
      return;
    }
    Clipboard.setData(ClipboardData(text: data));
    _showSnack('结果已复制到剪切板');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
