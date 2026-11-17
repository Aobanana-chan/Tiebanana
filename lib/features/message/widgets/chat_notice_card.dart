import 'package:flutter/material.dart';
import 'package:tiebanana/features/message/state/chat_content.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

/// 官方通知采用独立通栏卡片，不套用个人聊天的头像和气泡。
class ChatNoticeCard extends StatelessWidget {
  const ChatNoticeCard({super.key, required this.data, this.onOpen});
  final ChatNoticeCardData data;
  final ValueChanged<Uri>? onOpen;

  Future<void> _open(BuildContext context) async {
    final Uri? link = data.link;
    if (link == null) return;
    if (onOpen != null) {
      onOpen!(link);
      return;
    }
    bool opened = false;
    try {
      opened = await launchUrl(link, mode: LaunchMode.externalApplication);
    } catch (_) {/* 保留卡片，不让外部应用失败影响消息列表。 */}
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('暂时无法打开链接')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: tokens.cardShadow),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: data.link == null ? null : () => _open(context),
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (data.title.isNotEmpty)
                          Text(data.title,
                              style: text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: tokens.textPrimary)),
                        if (data.imageUrl.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: AspectRatio(
                                  aspectRatio: 3.05,
                                  child: Image.network(data.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => ColoredBox(
                                          color: tokens.fill,
                                          child: Icon(
                                              Icons.broken_image_outlined,
                                              color: tokens.textTertiary))))),
                        ],
                        if (data.text.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(data.text,
                              style: text.bodyMedium?.copyWith(
                                  color: tokens.textSecondary, height: 1.5)),
                        ],
                        if (data.link != null) ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            Text('查看全文',
                                style: text.bodyLarge
                                    ?.copyWith(color: tokens.textPrimary)),
                            const Spacer(),
                            Icon(Icons.chevron_right,
                                color: tokens.textTertiary)
                          ]),
                        ],
                      ])),
            )),
      ),
    );
  }
}
