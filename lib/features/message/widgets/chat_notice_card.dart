import 'package:flutter/material.dart';
import 'package:tiebanana/features/message/state/chat_content.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

/// 官方通知采用独立通栏卡片，不套用个人聊天的头像和气泡。
class ChatNoticeCard extends StatelessWidget {
  const ChatNoticeCard(
      {super.key, required this.data, this.onOpen, this.blockLinks = false});
  final ChatNoticeCardData data;
  final ValueChanged<Uri>? onOpen;

  /// 只读官方会话（userType 3/4）没有回复能力，卡片不再把用户带出应用；
  /// 只提示不支持，避免误触收银台或外部浏览器。
  final bool blockLinks;

  Future<void> _open(BuildContext context) async {
    final Uri? link = data.link;
    if (link == null) return;
    if (blockLinks) {
      await _showUnsupported(context, '该通知的详情暂不支持打开。');
      return;
    }
    // 支付相关页面统一拦截，避免把用户带到收银台；卡片本身仍完整展示。
    if (chatLinkNeedsPayment(link)) {
      await _showUnsupported(context, '该通知的详情页属于支付相关页面，当前版本暂不支持打开。');
      return;
    }
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

  Future<void> _showUnsupported(BuildContext context, String message) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('暂不支持'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
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
