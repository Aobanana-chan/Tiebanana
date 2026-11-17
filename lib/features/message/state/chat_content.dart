import 'dart:convert';

/// 官方 IM 消息内容类型（对照 APK `TbEnum.MsgContentType`）。
///
/// 命名只描述协议字段，不表示界面一定要单独渲染；未知类型仍回退到
/// “暂不支持的消息”，不把原始 JSON 直接塞进气泡或会话摘要。
abstract final class ChatMessageType {
  static const int text = 1;
  static const int image = 2;
  static const int voice = 3;
  static const int bigEmotion = 4;
  static const int inviteGroup = 5;
  static const int activity = 6;

  /// 图文消息；官方 `ChatMessage.getType` 把 7 / 35 都映射到
  /// `TYPE_MSG_MULTI_PIC_TEXT`，内容为 JSON 数组。
  static const int picText = 7;
  static const int extra = 9;
  static const int notify = 10;
  static const int system = 11;
  static const int topicUpdate = 12;

  /// 已读回执，不进入聊天正文。
  static const int readReceipt = 22;
  static const int replyCard = 23;
  static const int photoLive = 25;
  static const int breakIce = 30;
  static const int shareThread = 32;
  static const int shareForum = 33;
  static const int gameplayOrder = 34;
  static const int questionThread = 35;
  static const int shareChatroom = 37;
  static const int commonShareCard = 38;
  static const int gameplaySendCard = 40;
  static const int textGenImage = 101;
  static const int singleTextImage = 102;

  /// 文字转语音消息；官方 `TbTextToSpeechMsg extends TbTextMsg`，正文仍是文本。
  static const int textToSpeech = 103;

  static const int systemRecall = 7002;
  static const int systemShareForum = 7009;
  static const int systemShareThread = 7010;
  static const int systemRecallPersonal = 7015;
  static const int systemShareChatroom = 7020;
  static const int systemShareCommon = 7021;
  static const int systemActivity = 7022;
  static const int systemRecallAlternative = 7023;
  static const int systemDelete = 7025;
  static const int emojiReply = 20000;
  static const int strangerTip = 8001;
}

class ChatNoticeCardData {
  const ChatNoticeCardData(
      {required this.title, required this.text, this.imageUrl = '', this.link});
  final String title;
  final String text;
  final String imageUrl;
  final Uri? link;
}

/// 官方会员收银台/会员中心所在的业务模块。仅按模块路径判断，避免误伤
/// 正常的吧页、帖子与帮助页；远程配置可能替换完整 URL，但模块名保持不变。
const List<String> _paymentPathMarkers = <String>[
  'hybrid-business-vip',
  'paypanel',
];

/// 是否为官方支付相关页面（收银台、会员中心、一键签到等）。
bool chatLinkNeedsPayment(Uri uri) {
  final String path = uri.path.toLowerCase();
  for (final String marker in _paymentPathMarkers) {
    if (path.contains(marker)) return true;
  }
  return false;
}

/// 仅接受 HTTP(S) 图片和跳转，不执行消息内携带的任意 URI scheme。
Uri? chatNoticeUri(Object? value) {
  if (value is! String) return null;
  final String text = value.trim();
  final Uri? uri = Uri.tryParse(text.startsWith('//') ? 'https:$text' : text);
  return uri != null &&
          (uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty
      ? uri
      : null;
}

/// 是否需要在聊天正文里显示。已读回执 22 是控制事件，旧缓存或推送路径
/// 漏进来时也不能画成“暂不支持的消息”。
bool chatMessageVisible(int type) => type != ChatMessageType.readReceipt;

Object? _decodePayload(String content) {
  String text = content.trim();
  // 官方语音等消息的 content 会包一层 «…»，先剥掉再解析。
  if (text.length >= 2 && text.startsWith('«') && text.endsWith('»')) {
    text = text.substring(1, text.length - 1).trim();
  }
  if (text.isEmpty) return null;
  try {
    return jsonDecode(text);
  } on FormatException {
    return null;
  }
}

Map<Object?, Object?>? _asMap(Object? value) {
  if (value is Map) return value;
  if (value is String) {
    final Object? decoded = _decodePayload(value);
    if (decoded is Map) return decoded;
  }
  return null;
}

/// 把卡片里的 `text` / 系统消息正文等转成可读文本。
///
/// 类型 7 的 `text` 可能是 `TextContent` JSON（`thread_title`、`reply`、
/// `rich_title` 等），直接展示会把 JSON 暴露给用户。
String _readableTextValue(Object? value, [int depth = 0]) {
  if (value == null || depth > 3) return '';
  // 卡片里的 text/title 如果是数字等标量，视为没有可读内容，不能把
  // `[{"text":3}]` 渲染成消息正文。
  if (value is num || value is bool) return '';
  if (value is String) {
    final String text = value.trim();
    if (text.isEmpty) return '';
    final Object? decoded = _decodePayload(text);
    if (decoded is Map || decoded is List) {
      return _readableTextValue(decoded, depth + 1);
    }
    if (text.startsWith('{') || text.startsWith('[')) return '';
    return text;
  }
  if (value is List) {
    final List<String> parts = <String>[];
    for (final Object? item in value) {
      final String part = _readableTextValue(item, depth + 1);
      if (part.isNotEmpty && !parts.contains(part)) parts.add(part);
    }
    return parts.join(' ');
  }
  if (value is Map) {
    // 优先取用户能看懂的一段；rich_title 是带样式的标题片段。
    const List<String> keys = <String>[
      'tips',
      'guide_text',
      'thread_title',
      'reply',
      'text',
      'msg_content',
      'content',
      'title',
      'forum_name',
    ];
    for (final String key in keys) {
      final String part = _readableTextValue(value[key], depth + 1);
      if (part.isNotEmpty) return part;
    }
    final String rich = _readableTextValue(value['rich_title'], depth + 1);
    if (rich.isNotEmpty) return rich;
    return '';
  }
  return '';
}

/// 系统通知/普通 JSON 正文的降级文本。解析不出可读字段时返回 null，
/// 让调用方使用自己的兜底文案。
String? _readablePayload(String content) {
  final String raw = content.trim();
  if (raw.isEmpty) return null;
  final Object? decoded = _decodePayload(raw);
  if (decoded == null) return raw;
  // `"123"` 这类正文是纯文本，不是需要过滤的 JSON 对象。
  if (decoded is! Map && decoded is! List) return raw;
  final String text = _readableTextValue(decoded);
  return text.isEmpty ? null : text;
}

/// 图文卡片（类型 7 / 35）。官方客户端用 `vmb.c` 解析 `content`：
/// JSON 数组，每项包含 title/text/src/url/jump_url 等字段。
List<ChatNoticeCardData> chatNoticeCards(String content) {
  final Object? decoded = _decodePayload(content);
  final Iterable<Object?> items = decoded is List
      ? decoded
      : decoded is Map
          ? <Object?>[decoded]
          : const <Object?>[];
  final List<ChatNoticeCardData> cards = <ChatNoticeCardData>[];
  for (final Object? item in items.take(20)) {
    if (item is! Map) continue;
    final Object? textValue = item['text'];
    final Map<Object?, Object?>? textMap = _asMap(textValue);
    final String title = _readableTextValue(item['title']);
    final String text = _readableTextValue(textValue);
    final String image = chatNoticeUri(item['src'])?.toString() ??
        chatNoticeUri(textMap?['pic_url'])?.toString() ??
        '';
    if (title.isEmpty && text.isEmpty && image.isEmpty) continue;
    cards.add(ChatNoticeCardData(
      title: title,
      text: text,
      imageUrl: image,
      link: chatNoticeUri(item['url']) ??
          chatNoticeUri(item['jump_url']) ??
          chatNoticeUri(item['jumpUrl']),
    ));
  }
  return cards;
}

/// 语音时长（秒）。官方 content 为 JSON，字段 `during_time`；部分路径
/// 直接用整数或把 json 包在 «…» 里。
int chatVoiceSeconds(String content) {
  final Object? decoded = _decodePayload(content);
  if (decoded is Map) {
    for (final String key in <String>[
      'during_time',
      'during',
      'duration',
    ]) {
      final Object? value = decoded[key];
      final int parsed =
          value is int ? value : int.tryParse('${value ?? ''}') ?? 0;
      if (parsed > 0) return parsed;
    }
  }
  final String raw = content.trim();
  return int.tryParse(raw) ?? 0;
}

/// 图片消息（2）、大表情（4）、AI 图文（101/102）的可展示图片地址。
///
/// 只接受 HTTP(S)，不把任意 scheme 交给图片加载器。优先大图，失败时
/// 由界面回退到文字占位。
String chatImageUrl(int type, String content) {
  final Map<Object?, Object?>? map = _asMap(content);
  if (map == null) return '';
  final List<String> keys = type == ChatMessageType.bigEmotion
      ? <String>['src', 'big_src', 'thumb_url', 'pic_url']
      : <String>['big_src', 'src', 'thumb_url', 'pic_url'];
  for (final String key in keys) {
    final String url = chatNoticeUri(map[key])?.toString() ?? '';
    if (url.isNotEmpty) return url;
  }
  return '';
}

/// 101/102 消息里的文字说明；没有时返回空串。
String chatImageCaption(int type, String content) {
  if (type != ChatMessageType.textGenImage &&
      type != ChatMessageType.singleTextImage) {
    return '';
  }
  final Map<Object?, Object?>? map = _asMap(content);
  if (map == null) return '';
  return _readableTextValue(map['text']);
}

/// 消息在聊天气泡和会话列表摘要里的可读文本。
String chatDisplayText(int type, String content, {bool summary = false}) {
  switch (type) {
    case ChatMessageType.text:
    case ChatMessageType.textToSpeech:
      return content;
    case ChatMessageType.image:
      return '[图片]';
    case ChatMessageType.voice:
      final int seconds = chatVoiceSeconds(content);
      return seconds > 0 ? '[语音] $seconds″' : '[语音]';
    case ChatMessageType.bigEmotion:
      return '[表情]';
    case ChatMessageType.inviteGroup:
      return '[群邀请]';
    case ChatMessageType.activity:
      return '[活动]';
    case ChatMessageType.picText:
    case ChatMessageType.questionThread:
      final List<ChatNoticeCardData> cards = chatNoticeCards(content);
      if (cards.isEmpty) {
        return type == ChatMessageType.questionThread ? '问答消息' : '图文消息';
      }
      if (summary) {
        for (final ChatNoticeCardData card in cards) {
          if (card.text.isNotEmpty) return card.text;
        }
        for (final ChatNoticeCardData card in cards) {
          if (card.title.isNotEmpty) return card.title;
        }
        return '图文消息';
      }
      final List<String> parts = <String>[];
      for (final ChatNoticeCardData card in cards) {
        if (card.title.isNotEmpty) parts.add(card.title);
        if (card.text.isNotEmpty) parts.add(card.text);
      }
      return parts.isEmpty ? '图文消息' : parts.join('\n');
    case ChatMessageType.extra:
      return _readablePayload(content) ?? '[消息]';
    case ChatMessageType.notify:
      return _readablePayload(content) ?? '[通知]';
    case ChatMessageType.system:
      return _readablePayload(content) ?? '[系统消息]';
    case ChatMessageType.topicUpdate:
      return _readablePayload(content) ?? '[主题更新]';
    case ChatMessageType.readReceipt:
      return '';
    case ChatMessageType.replyCard:
      return '[回复卡片]';
    case ChatMessageType.photoLive:
      return '[直播]';
    case ChatMessageType.breakIce:
      return '[破冰互动]';
    case ChatMessageType.shareThread:
      return '[分享帖子]';
    case ChatMessageType.shareForum:
      return '[分享吧]';
    case ChatMessageType.gameplayOrder:
      return '[订单消息]';
    case ChatMessageType.shareChatroom:
      return '[分享聊天室]';
    case ChatMessageType.commonShareCard:
      return '[分享卡片]';
    case ChatMessageType.gameplaySendCard:
      return '[游戏邀请]';
    case ChatMessageType.textGenImage:
    case ChatMessageType.singleTextImage:
      final String caption = chatImageCaption(type, content);
      if (caption.isNotEmpty) return caption;
      return type == ChatMessageType.textGenImage ? '[AI 图片]' : '[图文消息]';
    case ChatMessageType.systemRecall:
    case ChatMessageType.systemRecallPersonal:
    case ChatMessageType.systemRecallAlternative:
      return '[消息已撤回]';
    case ChatMessageType.systemShareForum:
      return '[分享吧]';
    case ChatMessageType.systemShareThread:
      return '[分享帖子]';
    case ChatMessageType.systemShareChatroom:
      return '[分享聊天室]';
    case ChatMessageType.systemShareCommon:
      return '[分享卡片]';
    case ChatMessageType.systemActivity:
      return '[活动]';
    case ChatMessageType.systemDelete:
      return '[消息已删除]';
    case ChatMessageType.emojiReply:
      return '[表情回复]';
    case ChatMessageType.strangerTip:
      return _readablePayload(content) ?? '[陌生人提示]';
    default:
      // 7001-7025 之间还有一批系统提示（禁言、解禁、公告修改等），
      // 负值类型是时间戳/订阅等控制消息。
      if ((type >= 7001 && type <= 7025) || type < 0) {
        return _readablePayload(content) ?? '[系统消息]';
      }
      return '暂不支持的消息';
  }
}
