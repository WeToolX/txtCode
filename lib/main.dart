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
    // 定义主色调
    const primaryColor = Color(0xFF0F9B8E);
    const backgroundColor = Color(0xFFF7F9FB);

    return MaterialApp(
      title: '文本扰动工具',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // 设置视觉密度为标准（Comfortable）
        visualDensity: VisualDensity.standard,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          surface: Colors.white,
          // 设置浅色背景上的容器色
          surfaceContainerHighest: const Color(0xFFF0F2F5),
          outline: const Color(0xFFE0E0E0),
        ),
        // 字体设置，优先使用更现代的字体
        fontFamilyFallback: const [
          'SF Pro Text',
          'MiSans',
          'HarmonyOS Sans',
          'Roboto',
          'PingFang SC',
          'Microsoft YaHei',
        ],
        textTheme: const TextTheme(
          titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            color: Color(0xFF333333),
            height: 1.5,
          ),
          labelLarge: TextStyle(fontWeight: FontWeight.w600),
        ),
        // 卡片样式统一
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: EdgeInsets.zero,
        ),
        // 输入框样式统一
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFAFAFA), // 极浅的灰色背景
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
        // 按钮样式统一
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: const BorderSide(color: primaryColor),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Switch 样式
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return null;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return primaryColor;
            return Colors.grey.shade200;
          }),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFF0F0F0),
          thickness: 1,
          space: 1,
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
  leftToRightMark,
  rightToLeftMark,
  wordJoiner,
  functionApplication,
  invisibleTimes,
  invisibleSeparator,
  invisiblePlus,
  reserved2065,
  languageTag,
  byteOrderMark,
  softHyphen,
}

class TextProcessorPage extends StatefulWidget {
  const TextProcessorPage({super.key});

  @override
  State<TextProcessorPage> createState() => _TextProcessorPageState();
}

class _TextProcessorPageState extends State<TextProcessorPage> {
  // 改为 16 以增加留白
  static const double _cardPadding = 16;
  static const double _gap = 16;

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
      '[微笑]',
      '[撇嘴]',
      '[色]',
      '[发呆]',
      '[得意]',
      '[流泪]',
      '[害羞]',
      '[闭嘴]',
      '[睡]',
      '[大哭]',
      '[尴尬]',
      '[发怒]',
      '[调皮]',
      '[呲牙]',
      '[惊讶]',
      '[难过]',
      '[囧]',
      '[抓狂]',
      '[吐]',
      '[偷笑]',
      '[愉快]',
      '[白眼]',
      '[傲慢]',
      '[困]',
      '[惊恐]',
      '[憨笑]',
      '[悠闲]',
      '[咒骂]',
      '[疑问]',
      '[嘘]',
      '[晕]',
      '[衰]',
      '[骷髅]',
      '[敲打]',
      '[再见]',
      '[擦汗]',
      '[抠鼻]',
      '[鼓掌]',
      '[坏笑]',
      '[右哼哼]',
      '[鄙视]',
      '[委屈]',
      '[快哭了]',
      '[阴险]',
      '[亲亲]',
      '[可怜]',
      '[笑脸]',
      '[生病]',
      '[脸红]',
      '[破涕为笑]',
      '[恐惧]',
      '[失望]',
      '[无语]',
      '[嘿哈]',
      '[捂脸]',
      '[奸笑]',
      '[机智]',
      '[皱眉]',
      '[耶]',
      '[吃瓜]',
      '[加油]',
      '[汗]',
      '[天啊]',
      '[Emm]',
      '[社会社会]',
      '[旺柴]',
      '[好的]',
      '[打脸]',
      '[哇]',
      '[翻白眼]',
      '[666]',
      '[让我看看]',
      '[叹气]',
      '[苦涩]',
      '[裂开]',
      '[嘴唇]',
      '[爱心]',
      '[心碎]',
      '[拥抱]',
      '[强]',
      '[弱]',
      '[握手]',
      '[胜利]',
      '[抱拳]',
      '[勾引]',
      '[拳头]',
      '[OK]',
      '[合十]',
      '[啤酒]',
      '[咖啡]',
      '[蛋糕]',
      '[玫瑰]',
      '[凋谢]',
      '[菜刀]',
      '[炸弹]',
      '[便便]',
      '[月亮]',
      '[太阳]',
      '[庆祝]',
      '[礼物]',
      '[红包]',
      '[發]',
      '[福]',
      '[烟花]',
      '[爆竹]',
      '[猪头]',
      '[跳跳]',
      '[发抖]',
    ],
    EmojiPlatform.qq: [
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '🤣',
      '😂',
      '🙂',
      '🙃',
      '😉',
      '😊',
      '😇',
      '🥰',
      '😍',
      '🤩',
      '😘',
      '😗',
      '☺️',
      '😚',
      '😙',
      '😋',
      '😛',
      '😜',
      '🤪',
      '😝',
      '🤑',
      '🤗',
      '🤭',
      '🤫',
      '🤔',
      '🤐',
      '🤨',
      '😐',
      '😑',
      '😶',
      '😏',
      '😒',
      '🙄',
      '😬',
      '🤥',
      '😌',
      '😔',
      '😪',
      '🤤',
      '😴',
      '😷',
      '🤒',
      '🤕',
      '🤢',
      '🤮',
      '🤧',
      '🥵',
      '🥶',
      '🥴',
      '😵',
      '🤯',
      '🤠',
      '🥳',
      '😎',
      '🤓',
      '🧐',
      '😕',
      '😟',
      '🙁',
      '☹️',
      '😮',
      '😯',
      '😲',
      '😳',
      '🥺',
      '😦',
      '😧',
      '😨',
      '😰',
      '😥',
      '😢',
      '😭',
      '😱',
      '😖',
      '😣',
      '😞',
      '😓',
      '😩',
      '😫',
      '🥱',
      '😤',
      '😡',
      '😠',
      '🤬',
      '😈',
      '👿',
      '💀',
      '☠️',
      '💩',
      '🤡',
      '👹',
      '👺',
      '👻',
      '👽',
      '👾',
      '🤖',
      '😺',
      '😸',
      '😹',
      '😻',
      '😼',
      '😽',
      '🙀',
      '😿',
      '😾',
      '🙈',
      '🙉',
      '🙊',
      '👋',
      '🤚',
      '🖐️',
      '✋',
      '🖖',
      '👌',
      '🤏',
      '✌️',
      '🤞',
      '🤟',
      '🤘',
      '🤙',
      '👈',
      '👉',
      '👆',
      '🖕',
      '👇',
      '👍',
      '👎',
      '👊',
      '🤛',
      '🤜',
      '👏',
      '🙌',
      '👐',
      '🤲',
      '🤝',
      '🙏',
      '✍️',
      '💅',
      '🤳',
      '💪',
    ],
    EmojiPlatform.mo: [
      '[/哭笑]',
      '[/微笑]',
      '[/偷笑]',
      '[/得意]',
      '[/抠鼻]',
      '[/摊手]',
      '[/疑问]',
      '[/委屈巴巴]',
      '[/擦汗]',
      '[/尴尬]',
      '[/鼓掌]',
      '[/机智]',
      '[/恐惧]',
      '[/假哭]',
      '[/可怜]',
      '[/让我想想]',
      '[/崇拜]',
      '[/略略略]',
      '[/发怒]',
      '[/哒咩]',
      '[/鄙视]',
      '[/石化]',
      '[/闭嘴]',
      '[/摸头]',
      '[/抓狂]',
      '[/晕]',
      '[/再见]',
      '[/晚安]',
      '[/饿]',
      '[/加油]',
      '[/耶]',
      '[/坏笑]',
      '[/快哭了]',
      '[/难过]',
      '[/白眼]',
      '[/Emm]',
      '[/哼哼]',
      '[/好的]',
      '[/握手]',
      '[/拥抱]',
      '[/惊讶]',
      '[/撇嘴]',
      '[/头大]',
      '[/发呆]',
      '[/我好方]',
      '[/星星眼]',
      '[/脸红]',
      '[/捏脸]',
      '[/无奈]',
      '[/嘘]',
      '[/口罩]',
      '[/苦涩]',
      '[/嫌弃]',
      '[/气到炸裂]',
      '[/阴险]',
      '[/失望]',
      '[/敬礼]',
      '[/强撑]',
      '[/戳手]',
      '[/惊吓]',
      '[/流泪]',
      '[/皱眉]',
      '[/叹气]',
      '[/无语]',
      '[/社会]',
      '[/呆住]',
      '[/搓手]',
      '[/偷看]',
      '[/头秃]',
      '[/吐血]',
      '[/嘿哈]',
      '[/微醺]',
      '[/愉快]',
      '[/奸笑]',
      '[/真棒]',
      '[/生气]',
      '[/裂开]',
      '[/不屑]',
      '[/卒]',
      '[/不要想]',
      '[/热化了]',
      '[/暗中观察]',
      '[/飞吻]',
      '[/爱心]',
      '[/心碎]',
      '[/投降]',
      '[/搬砖]',
      '[/打工人]',
      '[/摸鱼]',
      '[/打call]',
      '[/吐]',
      '[/太爱了]',
      '[/笑yue了]',
      '[/六六六]',
      '[/生病]',
      '[/YYDS]',
      '[/佛系]',
      '[/吃瓜]',
      '[/在吗]',
      '[/摸锦鲤]',
      '[/小丑]',
      '[/夺笋]',
      '[/红包]',
      '[/炸弹]',
      '[/庆祝]',
      '[/烟花]',
      '[/爆竹]',
      '[/太阳]',
      '[/玫瑰]',
      '[/凋谢]',
      '[/发]',
      '[/中]',
      '[/嘴唇]',
      '[/菜刀]',
      '[/大便]',
      '[/咖啡]',
      '[/蛋糕]',
      '[/月亮]',
      '[/猪头]',
      '[/DOG]',
      '[/辣鸡]',
      '[/干杯]',
      '[/礼物]',
      '[/点赞]',
      '[/弱]',
      '[/勾引]',
      '[/肌肉]',
      '[/拳头]',
      '[/抱拳]',
      '[/合十]',
      '[/OK]',
      '[/摆手]',
      '[/胜利]',
      '[/福]',
    ],
    EmojiPlatform.universal: [
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '🤣',
      '😂',
      '🙂',
      '🙃',
      '😉',
      '😊',
      '😇',
      '🥰',
      '😍',
      '🤩',
      '😘',
      '😗',
      '☺️',
      '😚',
      '😙',
      '😋',
      '😛',
      '😜',
      '🤪',
      '😝',
      '🤑',
      '🤗',
      '🤭',
      '🤫',
      '🤔',
      '🤐',
      '🤨',
      '😐',
      '😑',
      '😶',
      '😏',
      '😒',
      '🙄',
      '😬',
      '🤥',
      '😌',
      '😔',
      '😪',
      '🤤',
      '😴',
      '😷',
      '🤒',
      '🤕',
      '🤢',
      '🤮',
      '🤧',
      '🥵',
      '🥶',
      '🥴',
      '😵',
      '🤯',
      '🤠',
      '🥳',
      '😎',
      '🤓',
      '🧐',
      '😕',
      '😟',
      '🙁',
      '☹️',
      '😮',
      '😯',
      '😲',
      '😳',
      '🥺',
      '😦',
      '😧',
      '😨',
      '😰',
      '😥',
      '😢',
      '😭',
      '😱',
      '😖',
      '😣',
      '😞',
      '😓',
      '😩',
      '😫',
      '🥱',
      '😤',
      '😡',
      '😠',
      '🤬',
      '😈',
      '👿',
      '💀',
      '☠️',
      '💩',
      '🤡',
      '👹',
      '👺',
      '👻',
      '👽',
      '👾',
      '🤖',
      '😺',
      '😸',
      '😹',
      '😻',
      '😼',
      '😽',
      '🙀',
      '😿',
      '😾',
      '🙈',
      '🙉',
      '🙊',
      '👋',
      '🤚',
      '🖐️',
      '✋',
      '🖖',
      '👌',
      '🤏',
      '✌️',
      '🤞',
      '🤟',
      '🤘',
      '🤙',
      '👈',
      '👉',
      '👆',
      '🖕',
      '👇',
      '👍',
      '👎',
      '👊',
      '🤛',
      '🤜',
      '👏',
      '🙌',
      '👐',
      '🤲',
      '🤝',
      '🙏',
      '✍️',
      '💅',
      '🤳',
      '💪',
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
    ZeroWidthType.invisibleTimes: '\u2062',
    ZeroWidthType.invisiblePlus: '\u2064',
    ZeroWidthType.reserved2065: '\u2065',
    ZeroWidthType.languageTag: '\u{E0001}',
    ZeroWidthType.byteOrderMark: '\uFEFF',
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
      // 移除 AppBar 的阴影，使用背景色
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        toolbarHeight: 56,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.security,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '文本扰动工具',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '关于',
            onPressed: () {
              _showSnack('未知者科技出品');
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            // 增加外部边距
            const horizontalPadding = 24.0;
            final spacing = isWide ? 24.0 : 16.0;

            final List<Widget> mainWorkArea = [
              _buildInputCard(),
              if (!isWide) ...[
                const SizedBox(height: 16),
                _buildSettingsCard(),
              ],
              const SizedBox(height: 16),
              _buildFileOpsCard(),
              const SizedBox(height: 16),
              _buildOutputCard(),
            ];

            if (isWide) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(horizontalPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: Column(children: mainWorkArea)),
                    SizedBox(width: spacing),
                    Expanded(
                      flex: 3,
                      child: Column(children: [_buildSettingsCard()]),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(horizontalPadding),
              child: Column(children: mainWorkArea),
            );
          },
        ),
      ),
    );
  }

  // === 辅助组件：带图标的标题 ===
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  // === 设置卡片：使用列表风格，增加图标 ===
  Widget _buildSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _cardPadding,
                12,
                _cardPadding,
                8,
              ),
              child: Text(
                '处理配置',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(),

            // 表情设置
            _buildSettingGroupHeader(Icons.emoji_emotions_outlined, '表情包混淆'),
            _buildEmojiContent(),
            const Divider(indent: 16, endIndent: 16),

            // 数字设置
            _buildSettingGroupHeader(Icons.numbers, '数字映射'),
            _buildDigitContent(),
            const Divider(indent: 16, endIndent: 16),

            // 0宽字符设置
            _buildSettingGroupHeader(Icons.visibility_off_outlined, '隐形字符注入'),
            _buildZeroWidthContent(),

            const Divider(),
            // 调试
            _buildDebugContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingGroupHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('原始文本', Icons.edit_note),
            TextField(
              controller: _inputController,
              minLines: 4,
              maxLines: 8,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                hintText: '在此输入或粘贴需要处理的敏感文本...',
              ),
            ),
            const SizedBox(height: _gap),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearInput,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('清空'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.paste, size: 18),
                    label: const Text('粘贴并填入'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                    ),
                  ),
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
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          title: const Text('启用表情插入', style: TextStyle(fontSize: 14)),
          subtitle: Text(_enableEmoji ? '随机插入表情字符' : '不插入表情',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          value: _enableEmoji,
          onChanged: (value) => setState(() => _enableEmoji = value),
        ),
        if (_enableEmoji) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<EmojiPlatform>(
              isExpanded: true,
              // 设置弹窗菜单的属性
              menuMaxHeight: 300,
              borderRadius: BorderRadius.circular(12),
              dropdownColor: Colors.white,
              elevation: 4,
              decoration: const InputDecoration(
                labelText: '表情风格',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                prefixIcon: Icon(Icons.face, color: Colors.grey),
              ),
              initialValue: _emojiPlatform,
              // 自定义选中后在输入框里的显示样式（保持简洁）
              selectedItemBuilder: (BuildContext context) {
                return EmojiPlatform.values.map<Widget>((EmojiPlatform platform) {
                  return Text(
                    _platformLabel(platform),
                    style: const TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  );
                }).toList();
              },
              // 自定义下拉菜单里的样式（丰富多彩）
              items: EmojiPlatform.values.map((platform) {
                final isSelected = _emojiPlatform == platform;
                final color = _getPlatformColor(platform);
                return DropdownMenuItem(
                  value: platform,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected ? color.withValues(alpha: 0.1) : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isSelected ? color : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _getPlatformIcon(platform),
                          size: 18,
                          color: isSelected ? color : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _platformLabel(platform),
                            style: TextStyle(
                              color: isSelected ? color : Colors.black87,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check, size: 18, color: color),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _emojiPlatform = value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('插入密度', style: TextStyle(fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(_emojiProbability * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: _emojiProbability,
                    max: 1.0,
                    divisions: 20,
                    label: '${(_emojiProbability * 100).toStringAsFixed(0)}%',
                    onChanged: (value) => setState(() => _emojiProbability = value),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // === 新增的两个辅助方法，用于获取颜色和图标 ===
  
  Color _getPlatformColor(EmojiPlatform platform) {
    switch (platform) {
      case EmojiPlatform.wx:
        return const Color(0xFF07C160); // 微信绿
      case EmojiPlatform.qq:
        return const Color(0xFF12B7F5); // QQ蓝
      case EmojiPlatform.mo:
        return const Color(0xFF624AF8); // 陌陌紫/蓝
      case EmojiPlatform.universal:
        return const Color(0xFFFFB300); // Emoji黄
    }
  }

  IconData _getPlatformIcon(EmojiPlatform platform) {
    switch (platform) {
      case EmojiPlatform.wx:
        return Icons.wechat; // 需要确保 context 支持，或改用 Icons.chat_bubble
      case EmojiPlatform.qq:
        return Icons.flutter_dash; // 代替企鹅
      case EmojiPlatform.mo:
        return Icons.location_on; // 代替定位/附近
      case EmojiPlatform.universal:
        return Icons.emoji_emotions;
    }
  }

  Widget _buildDigitContent() {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text('启用数字映射', style: TextStyle(fontSize: 14)),
          subtitle: const Text(
            '将 0-9 替换为特殊样式',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          value: _enableDigitMapping,
          onChanged: (value) => setState(() => _enableDigitMapping = value),
        ),
        if (_enableDigitMapping) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<DigitStyle>(
              decoration: const InputDecoration(
                labelText: '样式选择',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              initialValue: _digitStyle,
              items: DigitStyle.values.map((style) {
                return DropdownMenuItem(
                  value: style,
                  child: Text(_digitStyleLabel(style)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _digitStyle = value);
              },
            ),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text('启用零宽字符', style: TextStyle(fontSize: 14)),
          subtitle: const Text(
            '插入肉眼不可见的隐形字符',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          value: _enableZeroWidth,
          onChanged: (value) => setState(() => _enableZeroWidth = value),
        ),
        if (_enableZeroWidth) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _zeroWidthMinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '最小数量',
                      isDense: true,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                const Text('-', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _zeroWidthMaxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '最大数量',
                      isDense: true,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: DropdownButtonFormField<ZeroWidthType>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: '字符类型',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              initialValue: _zeroWidthType,
              items: ZeroWidthType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    _zeroWidthLabel(type),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _zeroWidthType = value);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDebugContent() {
    return CheckboxListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: const Text('调试模式：显形隐形字符', style: TextStyle(fontSize: 14)),
      value: _showZeroWidthMarkers,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Colors.orange,
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
            _buildSectionTitle('文件与执行', Icons.terminal),
            TextField(
              controller: _filePathController,
              decoration: const InputDecoration(
                labelText: '文件路径',
                hintText: '例如: C:\\Documents\\data.txt',
                prefixIcon: Icon(Icons.folder_outlined, size: 20),
              ),
            ),
            const SizedBox(height: _gap),

            // 使用 SegmentedButton 风格的布局或 Row
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _executeConversion,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('立即转换'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 45),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _loadFromFile,
                    icon: const Icon(Icons.file_upload_outlined),
                    label: const Text('读取文件'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saveToFile,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('保存结果'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 统计信息作为头部背景条
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    children: [
                      _buildStatChip('原字符长', '$_originalLength'),
                      _buildStatChip(
                        '现字符长',
                        '$_convertedLength',
                        isHighlight: true,
                      ),
                      _buildStatChip(
                        '0宽字符个数',
                        '$_zeroWidthCount',
                        isHighlight: _zeroWidthCount > 0,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '重新计算',
                  icon: const Icon(Icons.refresh, size: 20),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: _executeConversion,
                ),
              ],
            ),
          ),

          // 内容区
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(_cardPadding),
                child: TextField(
                  controller: _outputController,
                  minLines: 6,
                  maxLines: 12,
                  readOnly: _showZeroWidthMarkers,
                  style: const TextStyle(fontSize: 16, height: 1.6),
                  decoration: InputDecoration(
                    hintText: '处理后的文本将显示在这里...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
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
              ),
              Positioned(
                top: 24,
                right: 24,
                child: FloatingActionButton.small(
                  heroTag: 'copy_btn',
                  tooltip: '复制结果',
                  elevation: 2,
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  onPressed: _copyResult,
                  child: const Icon(Icons.copy, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isHighlight ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isHighlight ? Theme.of(context).primaryColor.withValues(alpha: 0.3) : Colors.transparent),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: '$label: ', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            TextSpan(text: value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isHighlight ? Theme.of(context).primaryColor : Colors.black87)),
          ]
        ),
      ),
    );
  }


  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _inputController.text = data!.text!;
      _showSnack('已粘贴剪贴板内容', isSuccess: true);
    }
  }

  void _clearInput() {
    _inputController.clear();
  }

  Future<void> _loadFromFile() async {
    final path = _filePathController.text.trim();
    if (path.isEmpty) {
      _showSnack('请先填写文件路径', isError: true);
      return;
    }
    try {
      final file = File(path);
      final content = await file.readAsString();
      if (!mounted) return;
      setState(() {
        _inputController.text = content;
      });
      _showSnack('已加载文件内容', isSuccess: true);
    } catch (e) {
      _showSnack('读取失败: $e', isError: true);
    }
  }

  Future<void> _saveToFile() async {
    final path = _filePathController.text.trim();
    if (path.isEmpty) {
      _showSnack('请先填写文件路径', isError: true);
      return;
    }
    final data = _lastConverted.isNotEmpty
        ? _lastConverted
        : _outputController.text;
    try {
      final file = File(path);
      await file.writeAsString(data);
      _showSnack('结果已写入 $path', isSuccess: true);
    } catch (e) {
      _showSnack('写入失败: $e', isError: true);
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

    // 添加轻微震动反馈（如果是移动端）
    HapticFeedback.mediumImpact();
    _showSnack('转换完成', isSuccess: true);
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
    final reg = RegExp(
      '[\u200b-\u200f\u2060-\u2065\uFEFF\u00AD\u{E0001}]',
      unicode: true,
    );
    return reg.allMatches(text).length;
  }

  String _markZeroWidth(String text) {
    final reg = RegExp(
      '[\u200b-\u200f\u2060-\u2065\uFEFF\u00AD\u{E0001}]',
      unicode: true,
    );
    return text.replaceAll(reg, '[0宽字符]');
  }

  String _platformLabel(EmojiPlatform platform) {
    switch (platform) {
      case EmojiPlatform.wx:
        return '微信';
      case EmojiPlatform.qq:
        return 'QQ';
      case EmojiPlatform.mo:
        return 'MoMo(陌陌)';
      case EmojiPlatform.universal:
        return '通用表情';
    }
  }

  String _digitStyleLabel(DigitStyle style) {
    switch (style) {
      case DigitStyle.fullWidth:
        return '全角数字 (０-９)';
      case DigitStyle.whiteCircle:
        return '白底圆圈 (⓪-⑨)';
      case DigitStyle.blackCircle:
        return '黑底圆圈 (⓿-❾)';
      case DigitStyle.mini:
        return '上标迷你 (⁰-⁹)';
      case DigitStyle.bracketed:
        return '中文括号 (（0）)';
    }
  }

  String _zeroWidthLabel(ZeroWidthType type) {
    switch (type) {
      case ZeroWidthType.zeroWidthSpace:
        return '零宽空格 (\\u200B)';
      case ZeroWidthType.zeroWidthNonJoiner:
        return '零宽非连字 (\\u200C)';
      case ZeroWidthType.zeroWidthJoiner:
        return '零宽连字 (\\u200D)';
      case ZeroWidthType.leftToRightMark:
        return '左到右标记 (\\u200E)';
      case ZeroWidthType.rightToLeftMark:
        return '右到左标记 (\\u200F)';
      case ZeroWidthType.wordJoiner:
        return '单词连接符 (\\u2060)';
      case ZeroWidthType.functionApplication:
        return '函数应用 (\\u2061)';
      case ZeroWidthType.invisibleTimes:
        return '不可见乘号 (\\u2062)';
      case ZeroWidthType.invisibleSeparator:
        return '不可见分隔符 (\\u2063)';
      case ZeroWidthType.invisiblePlus:
        return '不可见加号 (\\u2064)';
      case ZeroWidthType.reserved2065:
        return '保留字符 (\\u2065)';
      case ZeroWidthType.byteOrderMark:
        return 'BOM / 零宽不换行 (\\uFEFF)';
      case ZeroWidthType.softHyphen:
        return '软连字符 (\\u00AD)';
      case ZeroWidthType.languageTag:
        return '语言标签 (\\u{E0001})';
    }
  }

  void _copyResult() {
    final data = _lastConverted.isNotEmpty
        ? _lastConverted
        : _outputController.text;
    if (data.isEmpty) {
      _showSnack('没有可复制的内容', isError: true);
      return;
    }
    Clipboard.setData(ClipboardData(text: data));
    _showSnack('结果已复制到剪切板', isSuccess: true);
  }

  void _showSnack(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline
                  : (isSuccess
                        ? Icons.check_circle_outline
                        : Icons.info_outline),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? Colors.red.shade700
            : (isSuccess ? const Color(0xFF0F9B8E) : const Color(0xFF323232)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
