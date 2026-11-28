import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/message/state/notification_time.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 吧广播历史卡片。
///
/// 只展示协议给出的字段；没有点赞、评论、转发、收藏，也不显示审核状态。
class BroadcastCard extends StatefulWidget {
  const BroadcastCard({
    super.key,
    required this.item,
    required this.onOpenThread,
    this.desktop = false,
    this.onZoomImage,
  });

  final TiebaBroadcastItem item;
  final VoidCallback onOpenThread;
  final bool desktop;
  final VoidCallback? onZoomImage;

  @override
  State<BroadcastCard> createState() => _BroadcastCardState();
}

class _BroadcastCardState extends State<BroadcastCard> {
  bool _hovered = false;
  bool _expanded = false;

  /// 粗略判断是否超过 3 行：按典型 12.5px 字号、每行约 30 个汉字估算。
  /// 协议没有给排版信息，这里只用来避免短正文也出现「展开全文」。
  bool get _isLong {
    final String content = widget.item.content;
    if (content.isEmpty) return false;
    final int newlines = '\n'.allMatches(content).length;
    return newlines >= 3 || content.runes.length > 90;
  }

  void _handleTap() {
    if (widget.item.hasThread) {
      widget.onOpenThread();
    } else if (_isLong || _expanded) {
      setState(() => _expanded = !_expanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.desktop) {
      return _buildMobile(context);
    }
    return _buildDesktop(context);
  }

  Widget _buildMobile(BuildContext context) {
    final TiebaBroadcastItem item = widget.item;
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasThread = item.hasThread;
    final String time = broadcastTimeLabel(item.publishTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: TiebananaMetrics.brLg,
          onTap: () {
            if (hasThread) {
              widget.onOpenThread();
            } else {
              setState(() => _expanded = !_expanded);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(TiebananaMetrics.cardPadding),
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
                          if (item.hasTitle) ...<Widget>[
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall?.copyWith(
                                color: tokens.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (item.hasContent)
                            Text(
                              item.content,
                              maxLines: _expanded ? null : 3,
                              overflow: _expanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: tokens.textSecondary,
                                fontSize: 12.5,
                                height: 1.65,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (item.hasImage) ...<Widget>[
                      const SizedBox(width: 11),
                      _Thumb(
                        url: item.picUrl,
                        width: 88,
                        height: 66,
                        onTap: widget.onZoomImage,
                      ),
                    ],
                  ],
                ),
                if (time.isNotEmpty ||
                    item.pushUserCount > 0 ||
                    item.pv >= 0) ...<Widget>[
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: <Widget>[
                      if (time.isNotEmpty)
                        _Meta(
                          icon: Icons.schedule_rounded,
                          text: time,
                          tokens: tokens,
                        ),
                      if (item.pushUserCount > 0)
                        _Meta(
                          icon: Icons.groups_2_outlined,
                          text: '推送给 ${groupedCount(item.pushUserCount)} 人',
                          tokens: tokens,
                        ),
                      _Meta(
                        icon: Icons.visibility_outlined,
                        text: '阅读 ${groupedCount(item.pv)}',
                        tokens: tokens,
                      ),
                    ],
                  ),
                ],
                if (hasThread ||
                    (item.hasContent && !_expanded && _isLong) ||
                    _expanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: <Widget>[
                        Text(
                          hasThread ? '查看帖子' : (_expanded ? '收起' : '展开全文'),
                          style: TextStyle(
                            color: hasThread
                                ? tokens.primary
                                : tokens.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          hasThread
                              ? Icons.arrow_forward_rounded
                              : (_expanded
                                  ? Icons.expand_less
                                  : Icons.expand_more),
                          size: 13,
                          color:
                              hasThread ? tokens.primary : tokens.textTertiary,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final TiebaBroadcastItem item = widget.item;
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasThread = item.hasThread;
    final bool canExpand =
        !hasThread && ((item.hasContent && _isLong) || _expanded);
    final String time = broadcastTimeLabel(item.publishTime);
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
            onTap: (hasThread || canExpand) ? _handleTap : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
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
                            if (item.hasTitle) ...<Widget>[
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleSmall?.copyWith(
                                  color: tokens.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.42,
                                ),
                              ),
                              const SizedBox(height: 5),
                            ],
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
                        _Thumb(
                          url: item.picUrl,
                          width: 108,
                          height: 80,
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
                        Expanded(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: <Widget>[
                              if (time.isNotEmpty)
                                _Meta(
                                  icon: Icons.schedule_rounded,
                                  text: time,
                                  tokens: tokens,
                                  size: 11.5,
                                ),
                              if (item.pushUserCount > 0)
                                _Meta(
                                  icon: Icons.groups_2_outlined,
                                  text:
                                      '推送给 ${groupedCount(item.pushUserCount)} 人',
                                  tokens: tokens,
                                  size: 11.5,
                                ),
                              _Meta(
                                icon: Icons.visibility_outlined,
                                text: '阅读 ${groupedCount(item.pv)}',
                                tokens: tokens,
                                size: 11.5,
                              ),
                            ],
                          ),
                        ),
                        if (hasThread || canExpand) ...<Widget>[
                          const SizedBox(width: 12),
                          InkWell(
                            borderRadius: BorderRadius.circular(7),
                            onTap: _handleTap,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    hasThread
                                        ? '查看帖子'
                                        : (_expanded ? '收起' : '展开全文'),
                                    style: TextStyle(
                                      color: hasThread
                                          ? tokens.primary
                                          : tokens.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    hasThread
                                        ? Icons.arrow_forward_rounded
                                        : (_expanded
                                            ? Icons.expand_less_rounded
                                            : Icons.expand_more_rounded),
                                    size: 14,
                                    color: hasThread
                                        ? tokens.primary
                                        : tokens.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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

class _Thumb extends StatefulWidget {
  const _Thumb({
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
  State<_Thumb> createState() => _ThumbState();
}

class _ThumbState extends State<_Thumb> {
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

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.text,
    required this.tokens,
    this.size = 10.5,
  });

  final IconData icon;
  final String text;
  final TiebananaTokens tokens;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: size + 2.5, color: tokens.textTertiary),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: tokens.textTertiary,
            fontSize: size,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
