import 'dart:convert';

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

List<ChatNoticeCardData> chatNoticeCards(String content) {
  try {
    final Object? decoded = jsonDecode(content);
    if (decoded is! List) return const [];
    final List<ChatNoticeCardData> cards = [];
    for (final Object? item in decoded.take(20)) {
      if (item is! Map) continue;
      final String title =
          item['title'] is String ? (item['title'] as String).trim() : '';
      final String text =
          item['text'] is String ? (item['text'] as String).trim() : '';
      final String image = chatNoticeUri(item['src'])?.toString() ?? '';
      if (title.isEmpty && text.isEmpty && image.isEmpty) continue;
      cards.add(ChatNoticeCardData(
          title: title,
          text: text,
          imageUrl: image,
          link: chatNoticeUri(item['url'])));
    }
    return cards;
  } on FormatException {
    return const [];
  }
}

/// 类型 7 官方通知卡片的纯文本降级展示。不执行卡片 URL/HTML，
/// 不把未知 JSON 或图片地址作为正文直接展示。
String chatDisplayText(int type, String content, {bool summary = false}) {
  if (type == 1) return content;
  if (type != 7) return '暂不支持的消息';
  try {
    final Object? decoded = jsonDecode(content);
    if (decoded is! List) return '通知消息';
    final List<String> parts = <String>[];
    for (final Object? item in decoded.take(20)) {
      if (item is! Map) continue;
      final Object? title = item['title'];
      final Object? text = item['text'];
      if (summary && text is String && text.trim().isNotEmpty) {
        parts.add(text.trim());
      } else {
        if (title is String && title.trim().isNotEmpty) parts.add(title.trim());
        if (text is String && text.trim().isNotEmpty) parts.add(text.trim());
      }
    }
    return parts.isEmpty ? '通知消息' : parts.join(summary ? ' · ' : '\n');
  } on FormatException {
    return '通知消息';
  }
}
