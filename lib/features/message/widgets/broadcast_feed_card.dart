import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/message/state/notification_time.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/avatar_image.dart';

/// 吧广播聚合流里的一张卡。
///
/// 移动端保持紧凑单列卡片；桌面宽屏（[desktop] 为 true）增强来源吧直达、
/// 纯公告原地展开、配图灯箱预览、悬停跳转本吧历史与只读统计提示。
class BroadcastFeedCard extends StatefulWidget {
  const BroadcastFeedCard({
    super.key,
    required this.item,
    required this.onTap,
    this.desktop = false,
    this.onOpenForum,
    this.onOpenForumHistory,
    this.onZoomImage,
  });

  final TiebaBroadcastItem item;
  final VoidCallback onTap;
  final bool desktop;
  final VoidCallback? onOpenForum;
  final VoidCallback? onOpenForumHistory;
  final VoidCallback? onZoomImage;

  @override
  State<BroadcastFeedCard> createState() => _BroadcastFeedCardState();
}

class _BroadcastFeedCardState extends State<BroadcastFeedCard> {
  bool _hovered = false;
  bool _expanded = false;

  bool get _isLong {
    final String content = widget.item.content;
    if (content.isEmpty) return false;
    final int newlines = '\n'.allMatches(content).length;
    return newlines >= 3 || content.runes.length > 90;
  }

  void _handleCardTap() {
    if (widget.item.hasThread) {
      widget.onTap();
      return;
    }
    if (_isLong || _expanded) {
      setState(() => _expanded = !_expanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    if (!widget.desktop) {
      return _buildMobile(context, tokens);
    }
    return _buildDesktop(context, tokens);
  }

  Widget _buildMobile(BuildContext context, TiebananaTokens tokens) {
    final TiebaBroadcastItem item = widget.item;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(
          TiebananaMetrics.pageGutter, 0, TiebananaMetrics.pageGutter, 10),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: TiebananaMetrics.brLg,
          onTap: _handleCardTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (item.hasTitle)
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall?.copyWith(
                                color: tokens.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          if (item.hasTitle && item.hasContent)
                            const SizedBox(height: 6),
                          if (item.hasContent)
                            Text(
                              item.content,
                              maxLines: _expanded ? null : 4,
                              overflow: _expanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: tokens.textSecondary,
                                fontSize: 13.5,
                                height: 1.65,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (item.hasImage) ...<Widget>[
                      const SizedBox(width: 10),
                      _FeedThumb(
                        url: item.picUrl,
                        width: 92,
                        height: 72,
                        onTap: widget.onZoomImage,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    _ForumLine(item: item, tokens: tokens),
                    const Spacer(),
                    _Count(
                      icon: Icons.ios_share,
                      label: item.shareCount > 0
                          ? groupedCount(item.shareCount)
                          : '分享',
                      tokens: tokens,
                    ),
                    const SizedBox(width: 16),
                    _Count(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: groupedCount(item.commentCount),
                      tokens: tokens,
                    ),
                    const SizedBox(width: 16),
                    _Count(
                      icon: Icons.thumb_up_outlined,
                      label: groupedCount(item.likeCount),
                      tokens: tokens,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context, TiebananaTokens tokens) {
    final TiebaBroadcastItem item = widget.item;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasThread = item.hasThread;
    final bool canExpand = !hasThread && (_isLong || _expanded);
    final String clock =
        item.publishTime != null ? reminderClock(item.publishTime!) : '';
    final Color cardBg = _hovered
        ? Color.alphaBlend(
            tokens.primary.withValues(alpha: 0.035), tokens.surface)
        : tokens.surface;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: TiebananaMetrics.brLg,
          boxShadow: tokens.cardShadow,
          border: Border.all(
            color: _hovered ? tokens.line : Colors.transparent,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: TiebananaMetrics.brLg,
            onTap: (hasThread || canExpand) ? _handleCardTap : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _DesktopForumChip(
                        item: item,
                        tokens: tokens,
                        onTap: widget.onOpenForum,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color:
                              hasThread ? tokens.primaryContainer : tokens.fill,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          hasThread ? '关联贴' : '纯公告',
                          style: TextStyle(
                            color: hasThread
                                ? tokens.onPrimaryContainer
                                : tokens.textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (clock.isNotEmpty)
                        Text(
                          clock,
                          style: TextStyle(
                            color: tokens.textTertiary,
                            fontSize: 11.5,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (item.hasTitle)
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleSmall?.copyWith(
                                  color: tokens.textPrimary,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                              ),
                            if (item.hasTitle && item.hasContent)
                              const SizedBox(height: 5),
                            if (item.hasContent)
                              Text(
                                item.content,
                                maxLines: _expanded ? null : 3,
                                overflow: _expanded
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: tokens.textSecondary,
                                  fontSize: 13,
                                  height: 1.65,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (item.hasImage) ...<Widget>[
                        const SizedBox(width: 14),
                        _FeedThumb(
                          url: item.picUrl,
                          width: 116,
                          height: 86,
                          showZoomHint: true,
                          onTap: widget.onZoomImage,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 11),
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: tokens.line.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Tooltip(
                          message: hasThread ? '原帖只读统计' : '广播只读统计',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              _Count(
                                icon: Icons.ios_share,
                                label: item.shareCount > 0
                                    ? groupedCount(item.shareCount)
                                    : '分享',
                                tokens: tokens,
                              ),
                              const SizedBox(width: 14),
                              _Count(
                                icon: Icons.chat_bubble_outline_rounded,
                                label: groupedCount(item.commentCount),
                                tokens: tokens,
                              ),
                              const SizedBox(width: 14),
                              _Count(
                                icon: Icons.thumb_up_outlined,
                                label: groupedCount(item.likeCount),
                                tokens: tokens,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (item.forumId.isNotEmpty &&
                            widget.onOpenForumHistory != null)
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 140),
                            opacity: _hovered ? 1.0 : 0.0,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(7),
                                onTap: widget.onOpenForumHistory,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  child: Text(
                                    '本吧历史',
                                    style: TextStyle(
                                      color: tokens.textSecondary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (hasThread)
                          _ActionCue(
                            label: '查看原帖',
                            icon: Icons.arrow_forward_rounded,
                            color: tokens.primary,
                            onTap: widget.onTap,
                          )
                        else if (canExpand)
                          _ActionCue(
                            label: _expanded ? '收起' : '展开全文',
                            icon: _expanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: tokens.textSecondary,
                            onTap: _handleCardTap,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopForumChip extends StatefulWidget {
  const _DesktopForumChip({
    required this.item,
    required this.tokens,
    this.onTap,
  });

  final TiebaBroadcastItem item;
  final TiebananaTokens tokens;
  final VoidCallback? onTap;

  @override
  State<_DesktopForumChip> createState() => _DesktopForumChipState();
}

class _DesktopForumChipState extends State<_DesktopForumChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final String name = widget.item.forumName.trim();
    if (name.isEmpty) return const SizedBox.shrink();
    final String label = name.endsWith('吧') ? name : '$name吧';
    final TiebananaTokens tokens = widget.tokens;
    return Tooltip(
      message: '进入$label主页',
      child: MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.fromLTRB(4, 3, 9, 3),
            decoration: BoxDecoration(
              color: _hovered && widget.onTap != null
                  ? tokens.primaryContainer
                  : tokens.fill,
              borderRadius: TiebananaMetrics.brPill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _ForumAvatar(
                  name: label,
                  url: widget.item.forumAvatar,
                  tokens: tokens,
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _hovered && widget.onTap != null
                          ? tokens.onPrimaryContainer
                          : tokens.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCue extends StatelessWidget {
  const _ActionCue({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 3),
            Icon(icon, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

class _ForumLine extends StatelessWidget {
  const _ForumLine({required this.item, required this.tokens});

  final TiebaBroadcastItem item;
  final TiebananaTokens tokens;

  @override
  Widget build(BuildContext context) {
    final String name = item.forumName.trim();
    if (name.isEmpty) return const SizedBox.shrink();
    final String label = name.endsWith('吧') ? name : '$name吧';
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _ForumAvatar(name: label, url: item.forumAvatar, tokens: tokens),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForumAvatar extends StatelessWidget {
  const _ForumAvatar({
    required this.name,
    required this.url,
    required this.tokens,
  });

  final String name;
  final String url;
  final TiebananaTokens tokens;

  @override
  Widget build(BuildContext context) {
    final String letter = name.isEmpty ? '吧' : name.substring(0, 1);
    return ClipOval(
      child: SizedBox(
        width: 20,
        height: 20,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Container(
              color: tokens.primaryContainer,
              alignment: Alignment.center,
              child: Text(
                letter,
                style: TextStyle(
                  color: tokens.onPrimaryContainer,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (url.isNotEmpty) AvatarImage(url: url),
          ],
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({
    required this.icon,
    required this.label,
    required this.tokens,
  });

  final IconData icon;
  final String label;
  final TiebananaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15.5, color: tokens.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: tokens.textTertiary,
            fontSize: 12,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _FeedThumb extends StatefulWidget {
  const _FeedThumb({
    required this.url,
    required this.width,
    required this.height,
    this.showZoomHint = false,
    this.onTap,
  });

  final String url;
  final double width;
  final double height;
  final bool showZoomHint;
  final VoidCallback? onTap;

  @override
  State<_FeedThumb> createState() => _FeedThumbState();
}

class _FeedThumbState extends State<_FeedThumb> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final Widget image = ClipRRect(
      borderRadius: TiebananaMetrics.brSm,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.network(
              widget.url,
              fit: BoxFit.cover,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stack) {
                return ColoredBox(
                  color: tokens.fill,
                  child: Icon(Icons.image_not_supported_outlined,
                      size: 18, color: tokens.textTertiary),
                );
              },
              loadingBuilder: (BuildContext context, Widget child,
                  ImageChunkEvent? progress) {
                if (progress == null) return child;
                return ColoredBox(color: tokens.fill);
              },
            ),
            if (widget.showZoomHint)
              Positioned(
                right: 5,
                bottom: 5,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 140),
                  opacity: _hovered ? 1.0 : 0.0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0x8C0A0F18),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.zoom_in_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (widget.onTap == null) return image;
    return MouseRegion(
      cursor: SystemMouseCursors.zoomIn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: '查看大图',
          child: image,
        ),
      ),
    );
  }
}
