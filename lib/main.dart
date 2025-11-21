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
              bodyColor: const Color.fromARGB(185, 0, 0, 0),
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
  zeroWidthSpace, // \u200B 零宽空格
  zeroWidthNonJoiner, // \u200C 零宽非连字
  zeroWidthJoiner, // \u200D 零宽连字
  leftToRightMark, // \u200E 左到右标记
  rightToLeftMark, // \u200F 右到左标记
  wordJoiner, // \u2060 单词连接符
  functionApplication, // \u2061 函数应用
  invisibleTimes, // \u2062 不可见乘号 (新增)
  invisibleSeparator, // \u2063 不可见分隔符
  invisiblePlus, // \u2064 不可见加号 (新增)
  reserved2065, // \u2065 保留字符 (新增，原数组包含)
  languageTag, // \u{E0001} 语言标签 (新增)
  byteOrderMark, // \uFEFF BOM / 零宽不换行空格 (新增)
  softHyphen, // \u00AD 软连字符 (新增)
}

class TextProcessorPage extends StatefulWidget {
  const TextProcessorPage({super.key});

  @override
  State<TextProcessorPage> createState() => _TextProcessorPageState();
}

class _TextProcessorPageState extends State<TextProcessorPage> {
  static const double _cardPadding = 12; // 稍微增加一点内部padding
  static const double _gap = 10;

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
    EmojiPlatform.wx: [
      '[微笑]', '[撇嘴]', '[色]', '[发呆]', '[得意]', '[流泪]', '[害羞]', '[闭嘴]', '[睡]',
      '[大哭]',
      '[尴尬]', '[发怒]', '[调皮]', '[呲牙]', '[惊讶]', '[难过]', '[囧]', '[抓狂]', '[吐]',
      '[偷笑]',
      '[愉快]', '[白眼]', '[傲慢]', '[困]', '[惊恐]', '[憨笑]', '[悠闲]', '[咒骂]', '[疑问]', '[嘘]',
      '[晕]', '[衰]', '[骷髅]', '[敲打]', '[再见]', '[擦汗]', '[抠鼻]', '[鼓掌]', '[坏笑]',
      '[右哼哼]',
      '[鄙视]', '[委屈]', '[快哭了]', '[阴险]', '[亲亲]', '[可怜]', '[笑脸]', '[生病]', '[脸红]',
      '[破涕为笑]',
      '[恐惧]', '[失望]', '[无语]', '[嘿哈]', '[捂脸]', '[奸笑]', '[机智]', '[皱眉]', '[耶]', '[吃瓜]',
      '[加油]', '[汗]', '[天啊]', '[Emm]', '[社会社会]', '[旺柴]', '[好的]', '[打脸]', '[哇]',
      '[翻白眼]',
      '[666]', '[让我看看]', '[叹气]', '[苦涩]', '[裂开]', '[嘴唇]', '[爱心]', '[心碎]', '[拥抱]',
      '[强]',
      '[弱]', '[握手]', '[胜利]', '[抱拳]', '[勾引]', '[拳头]', '[OK]', '[合十]', '[啤酒]', '[咖啡]',
      '[蛋糕]', '[玫瑰]', '[凋谢]', '[菜刀]', '[炸弹]', '[便便]', '[月亮]', '[太阳]', '[庆祝]',
      '[礼物]',
      '[红包]', '[發]', '[福]', '[烟花]', '[爆竹]', '[猪头]', '[跳跳]', '[发抖]'
    ],
    EmojiPlatform.qq: [
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃', '😉', '😊',
      '😇', '🥰', '😍', '🤩', '😘', '😗', '☺️', '😚', '😙', '😋', '😛', '😜',
      '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨', '😐', '😑', '😶',
      '😏', '😒', '🙄', '😬', '🤥', '😌', '😔', '😪', '🤤', '😴', '😷', '🤒',
      '🤕', '🤢', '🤮', '🤧', '🥵', '🥶', '🥴', '😵', '🤯', '🤠', '🥳', '😎',
      '🤓', '🧐', '😕', '😟', '🙁', '☹️', '😮', '😯', '😲', '😳', '🥺', '😦',
      '😧', '😨', '😰', '😥', '😢', '😭', '😱', '😖', '😣', '😞', '😓', '😩',
      '😫', '🥱', '😤', '😡', '😠', '🤬', '😈', '👿', '💀', '☠️', '💩', '🤡',
      '👹', '👺', '👻', '👽', '👾', '🤖', '😺', '😸', '😹', '😻', '😼', '😽',
      '🙀', '😿', '😾', '🙈', '🙉', '🙊', '👋', '🤚', '🖐️', '✋', '🖖', '👌',
      '🤏', '✌️', '🤞', '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕', '👇', '👍',
      '👎', '👊', '🤛', '🤜', '👏', '🙌', '👐', '🤲', '🤝', '🙏', '✍️', '💅',
      '🤳', '💪'
    ],
    EmojiPlatform.mo: [
      '[/哭笑]', '[/微笑]', '[/偷笑]', '[/得意]', '[/抠鼻]', '[/摊手]', '[/疑问]', '[/委屈巴巴]',
      '[/擦汗]', '[/尴尬]',
      '[/鼓掌]', '[/机智]', '[/恐惧]', '[/假哭]', '[/可怜]', '[/让我想想]', '[/崇拜]', '[/略略略]',
      '[/发怒]', '[/哒咩]',
      '[/鄙视]', '[/石化]', '[/闭嘴]', '[/摸头]', '[/抓狂]', '[/晕]', '[/再见]', '[/晚安]', '[/饿]',
      '[/加油]',
      '[/耶]', '[/坏笑]', '[/快哭了]', '[/难过]', '[/白眼]', '[/Emm]', '[/哼哼]', '[/好的]', '[/握手]',
      '[/拥抱]',
      '[/惊讶]', '[/撇嘴]', '[/头大]', '[/发呆]', '[/我好方]', '[/星星眼]', '[/脸红]', '[/捏脸]', '[/无奈]',
      '[/嘘]',
      '[/口罩]', '[/苦涩]', '[/嫌弃]', '[/气到炸裂]', '[/阴险]', '[/失望]', '[/敬礼]', '[/强撑]', '[/戳手]',
      '[/惊吓]',
      '[/流泪]', '[/皱眉]', '[/叹气]', '[/无语]', '[/社会]', '[/呆住]', '[/搓手]', '[/偷看]', '[/头秃]',
      '[/吐血]',
      '[/嘿哈]', '[/微醺]', '[/愉快]', '[/奸笑]', '[/真棒]', '[/生气]', '[/裂开]', '[/不屑]', '[/卒]',
      '[/不要想]',
      '[/热化了]', '[/暗中观察]', '[/飞吻]', '[/爱心]', '[/心碎]', '[/投降]', '[/搬砖]', '[/打工人]',
      '[/摸鱼]', '[/打call]',
      '[/吐]', '[/太爱了]', '[/笑yue了]', '[/六六六]', '[/生病]', '[/YYDS]', '[/佛系]', '[/吃瓜]', '[/在吗]',
      '[/摸锦鲤]',
      '[/小丑]', '[/夺笋]', '[/红包]', '[/炸弹]', '[/庆祝]', '[/烟花]', '[/爆竹]', '[/太阳]', '[/玫瑰]',
      '[/凋谢]',
      '[/发]', '[/中]', '[/嘴唇]', '[/菜刀]', '[/大便]', '[/咖啡]', '[/蛋糕]', '[/月亮]', '[/猪头]',
      '[/DOG]',
      '[/辣鸡]', '[/干杯]', '[/礼物]', '[/点赞]', '[/弱]', '[/勾引]', '[/肌肉]', '[/拳头]', '[/抱拳]',
      '[/合十]',
      '[/OK]', '[/摆手]', '[/胜利]', '[/福]'
    ],
    EmojiPlatform.universal: [
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃', '😉', '😊',
      '😇', '🥰', '😍', '🤩', '😘', '😗', '☺️', '😚', '😙', '😋', '😛', '😜',
      '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨', '😐', '😑', '😶',
      '😏', '😒', '🙄', '😬', '🤥', '😌', '😔', '😪', '🤤', '😴', '😷', '🤒',
      '🤕', '🤢', '🤮', '🤧', '🥵', '🥶', '🥴', '😵', '🤯', '🤠', '🥳', '😎',
      '🤓', '🧐', '😕', '😟', '🙁', '☹️', '😮', '😯', '😲', '😳', '🥺', '😦',
      '😧', '😨', '😰', '😥', '😢', '😭', '😱', '😖', '😣', '😞', '😓', '😩',
      '😫', '🥱', '😤', '😡', '😠', '🤬', '😈', '👿', '💀', '☠️', '💩', '🤡',
      '👹', '👺', '👻', '👽', '👾', '🤖', '😺', '😸', '😹', '😻', '😼', '😽',
      '🙀', '😿', '😾', '🙈', '🙉', '🙊', '👋', '🤚', '🖐️', '✋', '🖖', '👌',
      '🤏', '✌️', '🤞', '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕', '👇', '👍',
      '👎', '👊', '🤛', '🤜', '👏', '🙌', '👐', '🤲', '🤝', '🙏', '✍️', '💅',
      '🤳', '💪'
    ],
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
    // 新增列表
    ZeroWidthType.invisibleTimes: '\u2062',
    ZeroWidthType.invisiblePlus: '\u2064',

    // \u2065 在 Unicode 中暂未分配(Reserved)，但为了匹配你的数组，这里将其加入
    ZeroWidthType.reserved2065: '\u2065',

    // 注意：超过 FFFF 的字符在 Dart 中必须使用 \u{...} 格式
    ZeroWidthType.languageTag: '\u{E0001}',

    // BOM / Zero Width No-Break Space
    ZeroWidthType.byteOrderMark: '\uFEFF',

    // Soft Hyphen (虽然平时不可见，但它其实有"换行暗示"的语义)
    ZeroWidthType.softHyphen: '\u00AD',
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
            // 断点逻辑：>= 900 为宽屏
            final isWide = constraints.maxWidth >= 900;
            const horizontalPadding = 16.0;
            final spacing = isWide ? 16.0 : 12.0;

            // 构建主要的操作卡片列表
            final List<Widget> mainWorkArea = [
              _buildInputCard(),
              if (!isWide) ...[
                const SizedBox(height: 12),
                _buildSettingsCard(), // 窄屏模式下，设置卡片在输入框下方
              ],
              const SizedBox(height: 12),
              _buildFileOpsCard(),
              const SizedBox(height: 12),
              _buildOutputCard(),
              const SizedBox(height: 12),
              _buildStatsRow(),
            ];

            // 宽屏模式下，使用 Row 布局，左侧为操作区，右侧为设置区
            if (isWide) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(horizontalPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左侧列：输入、文件、输出、统计
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
                          _buildInputCard(),
                          const SizedBox(height: 12),
                          _buildFileOpsCard(),
                          const SizedBox(height: 12),
                          _buildOutputCard(),
                          const SizedBox(height: 12),
                          _buildStatsRow(),
                        ],
                      ),
                    ),
                    SizedBox(width: spacing),
                    // 右侧列：统一的设置卡片
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildSettingsCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // 窄屏模式下，垂直排列
            return SingleChildScrollView(
              padding: const EdgeInsets.all(horizontalPadding),
              child: Column(
                children: mainWorkArea,
              ),
            );
          },
        ),
      ),
    );
  }

  // === 重构：统一设置卡片 ===
  Widget _buildSettingsCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题头
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(
                vertical: 8, horizontal: _cardPadding),
            child: Text(
              '处理设置',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          // 表情设置部分
          Padding(
            padding: const EdgeInsets.all(_cardPadding),
            child: _buildEmojiContent(),
          ),
          const Divider(height: 1),
          // 数字映射设置部分
          Padding(
            padding: const EdgeInsets.all(_cardPadding),
            child: _buildDigitContent(),
          ),
          const Divider(height: 1),
          // 0宽字符设置部分
          Padding(
            padding: const EdgeInsets.all(_cardPadding),
            child: _buildZeroWidthContent(),
          ),
          const Divider(height: 1),
          // 调试部分
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _cardPadding),
            child: _buildDebugContent(),
          ),
        ],
      ),
    );
  }

  // === 原 Card 构建方法改为 Content 构建方法 (去掉外层Card) ===

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

  Widget _buildEmojiContent() {
    return Column(
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
          const SizedBox(height: _gap),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<EmojiPlatform>(
                  isExpanded: true, // 防止溢出
                  decoration: const InputDecoration(
                    labelText: '表情包平台',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _emojiPlatform,
                  items: EmojiPlatform.values
                      .map(
                        (platform) => DropdownMenuItem(
                          value: platform,
                          child: Text(
                            _platformLabel(platform),
                            overflow: TextOverflow.ellipsis,
                          ),
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
            ],
          ),
          const SizedBox(height: 8),
          Column(
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
                max: 1.0,
                divisions: 100,
                label: '${(_emojiProbability * 100).toStringAsFixed(0)}%',
                onChanged: (value) => setState(() => _emojiProbability = value),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDigitContent() {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('是否映射数字'),
          value: _enableDigitMapping,
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          onChanged: (value) => setState(() => _enableDigitMapping = value),
        ),
        if (_enableDigitMapping) ...[
          const SizedBox(height: _gap),
          DropdownButtonFormField<DigitStyle>(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '数字样式',
            ),
            initialValue: _digitStyle,
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
      ],
    );
  }

  Widget _buildZeroWidthContent() {
    return Column(
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
          const SizedBox(height: _gap),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _zeroWidthMinController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '随机最小值',
                    hintText: '最小插入',
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
                    hintText: '最大插入',
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: _gap),
          DropdownButtonFormField<ZeroWidthType>(
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '0宽类型',
            ),
            initialValue: _zeroWidthType,
            items: ZeroWidthType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(
                      _zeroWidthLabel(type),
                      overflow: TextOverflow.ellipsis,
                    ),
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
    );
  }

  Widget _buildDebugContent() {
    return CheckboxListTile(
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
    final data =
        _lastConverted.isNotEmpty ? _lastConverted : _outputController.text;
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
    final displayText =
        _showZeroWidthMarkers ? _markZeroWidth(_lastConverted) : _lastConverted;
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
    final reg = RegExp(
        '[\\u200b-\\u200f\\u2060-\\u2065\\uFEFF\\u00AD\\u{E0001}]',
        unicode: true);
    return reg.allMatches(text).length;
  }

  String _markZeroWidth(String text) {
    final reg = RegExp(
        '[\\u200b-\\u200f\\u2060-\\u2065\\uFEFF\\u00AD\\u{E0001}]',
        unicode: true);
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
      case ZeroWidthType.invisibleTimes:
        return '隐形乘号 (\\u2062)';
      case ZeroWidthType.invisibleSeparator:
        return '隐形分隔 (\\u2063)';
      case ZeroWidthType.invisiblePlus:
        return '隐形加号 (\\u2064)';
      case ZeroWidthType.reserved2065:
        return '保留字符 (\\u2065)';
      case ZeroWidthType.byteOrderMark:
        return '零宽不换行/BOM (\\uFEFF)';
      case ZeroWidthType.softHyphen:
        return '软连字符 (\\u00AD)';
      case ZeroWidthType.languageTag:
        return '语言标签 (\\uE0001)';
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
    final data =
        _lastConverted.isNotEmpty ? _lastConverted : _outputController.text;
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