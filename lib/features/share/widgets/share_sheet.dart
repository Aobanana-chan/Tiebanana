import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tiebanana/features/share/models/share_content.dart';
import 'package:tiebanana/features/share/widgets/share_friend_picker.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/app_toast.dart';

/// 分享面板的入口动作。面板只负责收集选择，具体执行放在这里。
enum _ShareAction { friend, apps, copy }

/// 打开分享面板。
///
/// 顺序与官方一致：先分享给好友，再交给其他应用，最后才是复制链接。
Future<void> showShareSheet(BuildContext context, ShareContent content) async {
  final TiebananaTokens tokens = TiebananaTokens.of(context);
  final _ShareAction? action = await showModalBottomSheet<_ShareAction>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: tokens.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(TiebananaMetrics.radiusXl),
      ),
    ),
    builder: (BuildContext sheetContext) => _ShareSheet(content: content),
  );
  if (!context.mounted || action == null) return;

  if (action == _ShareAction.friend) {
    await showShareFriendPicker(context, content);
  } else if (action == _ShareAction.apps) {
    await _shareToApps(context, content);
  } else if (action == _ShareAction.copy) {
    await _copyLink(content);
  }
}

Future<void> _shareToApps(BuildContext context, ShareContent content) async {
  final Rect? origin = _shareOrigin(context);
  try {
    final ShareResult result = await SharePlus.instance.share(ShareParams(
      text: content.shareText,
      title: '分享到',
      subject: content.title,
      sharePositionOrigin: origin,
    ));
    if (result.status == ShareResultStatus.unavailable) {
      await Clipboard.setData(ClipboardData(text: content.url));
      Fluttertoast.showToast(msg: '分享失败，链接已复制');
    }
  } catch (_) {
    // 系统面板不可用时不让用户白点一次：直接落回复制链接。
    await Clipboard.setData(ClipboardData(text: content.url));
    Fluttertoast.showToast(msg: '分享失败，链接已复制');
  }
}

Future<void> _copyLink(ShareContent content) async {
  try {
    await Clipboard.setData(ClipboardData(text: content.url));
    Fluttertoast.showToast(msg: content.copiedMessage);
  } catch (_) {
    Fluttertoast.showToast(msg: '复制失败，请稍后再试');
  }
}

/// iPad 的系统分享面板需要锚点；其余平台会忽略它。
Rect? _shareOrigin(BuildContext context) {
  final RenderObject? renderObject = context.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) return null;
  return renderObject.localToGlobal(Offset.zero) & renderObject.size;
}

class _ShareSheet extends StatelessWidget {
  const _ShareSheet({required this.content});

  final ShareContent content;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '分享',
                    style: textTheme.titleMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: tokens.textSecondary,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('取消'),
                ),
              ],
            ),
            const SizedBox(height: TiebananaMetrics.gapXs),
            _preview(context, tokens, textTheme),
            const SizedBox(height: TiebananaMetrics.gapLg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _ShareTarget(
                    icon: Icons.people_alt_rounded,
                    label: '分享给好友',
                    onTap: () => Navigator.pop(context, _ShareAction.friend),
                  ),
                ),
                const SizedBox(width: TiebananaMetrics.gapSm),
                Expanded(
                  child: _ShareTarget(
                    icon: Icons.apps_rounded,
                    label: '其他应用',
                    onTap: () => Navigator.pop(context, _ShareAction.apps),
                  ),
                ),
                const SizedBox(width: TiebananaMetrics.gapSm),
                Expanded(
                  child: _ShareTarget(
                    icon: Icons.link_rounded,
                    label: '复制链接',
                    onTap: () => Navigator.pop(context, _ShareAction.copy),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TiebananaMetrics.gapSm),
            Text(
              '分享内容为链接，对方可在贴吧中打开',
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(color: tokens.textTertiary),
            ),
            const SizedBox(height: TiebananaMetrics.gapSm),
          ],
        ),
      ),
    );
  }

  Widget _preview(
    BuildContext context,
    TiebananaTokens tokens,
    TextTheme textTheme,
  ) {
    final String summary = content.summary.trim();
    final bool showSummary =
        summary.isNotEmpty && summary != content.title.trim();
    return Container(
      padding: const EdgeInsets.all(TiebananaMetrics.cardPadding),
      decoration: BoxDecoration(
        color: tokens.fill,
        borderRadius: TiebananaMetrics.brLg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tokens.primaryContainer,
              borderRadius: TiebananaMetrics.brCtl,
            ),
            child: Icon(
              content.icon,
              size: 23,
              color: tokens.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: TiebananaMetrics.gapMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  content.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: tokens.textPrimary,
                    height: 1.35,
                  ),
                ),
                if (showSummary) ...<Widget>[
                  const SizedBox(height: TiebananaMetrics.gapXs),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.public_rounded,
                      size: 13,
                      color: tokens.textTertiary,
                    ),
                    const SizedBox(width: TiebananaMetrics.gapXs),
                    Expanded(
                      child: Text(
                        content.footnote,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: tokens.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareTarget extends StatelessWidget {
  const _ShareTarget({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: TiebananaMetrics.brLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: tokens.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 25,
                  color: tokens.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: TiebananaMetrics.gapSm),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
