import 'package:flutter/material.dart';

/// 分享面板展示的内容。
///
/// 只描述「要分享什么」，不关心面板怎么画；帖子、话题、吧主页共用一套。
@immutable
class ShareContent {
  const ShareContent({
    required this.title,
    required this.url,
    this.summary = '',
    this.source = '百度贴吧',
    this.icon = Icons.article_outlined,
    this.copiedMessage = '链接已复制',
  });

  /// 标题。私信和系统分享都优先展示它。
  final String title;

  /// 可打开的分享链接。
  final String url;

  /// 摘要，可为空。
  final String summary;

  /// 来源说明，例如「抗压背锅吧」「话题」「用户名 · 回复」。
  final String source;

  /// 预览卡左侧的图标。
  final IconData icon;

  /// 复制成功后的提示。
  final String copiedMessage;

  /// 通过私信 / 系统面板分享时发送的正文。
  String get shareText => title.trim().isEmpty ? url : '$title\n$url';

  /// 来源 + 域名，用于预览卡底部。
  String get footnote {
    final Uri? uri = Uri.tryParse(url);
    final String host =
        uri == null || uri.host.isEmpty ? 'tieba.baidu.com' : uri.host;
    return source.trim().isEmpty ? host : '$source · $host';
  }
}
