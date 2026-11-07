import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 收藏列表的一行（概念图 `design/mockups/thread_store.html` 的 `.listrow`）。
///
/// 结构是「标题（最多两行）+ 元信息 / 新楼层徽章 + 右侧缩略图 / 选择圈」。
/// 外层的页面留白、投影与左滑操作由 `thread_store_page.dart` 负责 ——
/// 这样同一个行组件既能放进左滑容器，也能直接用在编辑态里。
class StoredThreadWidget extends StatelessWidget {
  const StoredThreadWidget({
    super.key,
    required this.info,
    this.deleteMode = false,
    this.selected = false,
    this.onTap,
    this.onToggleSelected,
  });

  final TiebaStoredThread info;

  /// 编辑态：整行点击切换选中状态。
  final bool deleteMode;

  /// 编辑态下这一行是否已选中。
  final bool selected;

  /// 正常态点击整行。
  final VoidCallback? onTap;

  /// 编辑态点击整行。
  final VoidCallback? onToggleSelected;

  /// 缩略图边长。收藏贴带 media 时在右侧显示缩略图，与标题同一行。
  static const double _thumbSize = 54;

  /// 元信息：作者名 + 接口给的「更新到第 N 楼」，数据来自 [TiebaStoredThread]。
  String get _meta {
    final List<String> parts = <String>[];
    if (info.name.isNotEmpty) {
      parts.add(info.name);
    }
    final String msg = info.postNoMsg?.trim() ?? "";
    if (msg.isNotEmpty) {
      parts.add(msg);
    }
    return parts.join(" · ");
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int newCount = info.newCount;
    final String? image = info.getImage;
    final bool hasMeta = _meta.isNotEmpty;
    final bool hasBadges = newCount > 0 || info.isDeleted;

    return Material(
      color: tokens.surface,
      borderRadius: TiebananaMetrics.brLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: TiebananaMetrics.brLg,
        onTap: deleteMode ? onToggleSelected : onTap,
        child: Padding(
          padding: const EdgeInsets.all(TiebananaMetrics.cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      info.title.isEmpty ? "（无标题）" : info.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: info.isDeleted
                            ? tokens.textTertiary
                            : tokens.textPrimary,
                      ),
                    ),
                    if (hasMeta || hasBadges) ...<Widget>[
                      const SizedBox(height: TiebananaMetrics.gapXs + 2),
                      Row(
                        children: <Widget>[
                          if (hasMeta)
                            Expanded(
                              child: Text(
                                _meta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.labelSmall
                                    ?.copyWith(color: tokens.textTertiary),
                              ),
                            ),
                          if (hasMeta && hasBadges)
                            const SizedBox(width: TiebananaMetrics.gapSm),
                          if (newCount > 0)
                            _Badge(
                              text: "$newCount 条更新",
                              background: tokens.primaryContainer,
                              foreground: tokens.onPrimaryContainer,
                            ),
                          if (newCount > 0 && info.isDeleted)
                            const SizedBox(width: TiebananaMetrics.gapXs),
                          if (info.isDeleted)
                            _Badge(
                              text: "该贴已删除",
                              background: tokens.fill,
                              foreground: tokens.danger,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (deleteMode) ...<Widget>[
                const SizedBox(width: TiebananaMetrics.gapMd),
                _SelectionMark(selected: selected),
              ] else ...<Widget>[
                if (image != null && image.isNotEmpty) ...<Widget>[
                  const SizedBox(width: TiebananaMetrics.gapMd),
                  ClipRRect(
                    borderRadius: TiebananaMetrics.brSm,
                    child: ExtendedImage.network(
                      image,
                      width: _thumbSize,
                      height: _thumbSize,
                      fit: BoxFit.cover,
                      cache: true,
                    ),
                  ),
                ],
                const SizedBox(width: TiebananaMetrics.gapXs),
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: tokens.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 小徽章：新楼层数 / 已删除。
class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TiebananaMetrics.gapXs + 2,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: TiebananaMetrics.brXs,
      ),
      child: Text(
        text,
        maxLines: 1,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 编辑态的圆形勾选标记（概念图 `.cb` / `.cb.on`）。
class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return AnimatedContainer(
      duration: TiebananaMetrics.durationFast,
      curve: TiebananaMetrics.curveStandard,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? tokens.accentFill : Colors.transparent,
        border: Border.all(
          color: selected ? tokens.accentFill : tokens.lineStrong,
          width: 1.5,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 14, color: tokens.accentOn)
          : null,
    );
  }
}
