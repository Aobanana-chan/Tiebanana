import 'package:flutter/material.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 「我的」页顶部的用户信息卡。
///
/// 在所有断点（1280 / 1080 / 820 / 640）下均为 100% 满宽横卡：
/// 左侧为 56dp 头像、昵称、ID（及真实吧龄）与个性签名；
/// 右侧（窄屏折行到下方满宽）为一字排开的四项统计（关注 | 粉丝 | 关注的吧 | 帖子）
/// 与「编辑资料」按钮，绝不折成 2×2 或半宽孤立卡。
class UserCard extends StatelessWidget {
  final String concernNum;
  final String fansNum;
  final String likeForumNum;
  final String postNum;
  final String portraitUrl;
  final String id;
  final String name;
  final String intro;
  final String tbAge;
  final EdgeInsetsGeometry? margin;

  const UserCard({
    super.key,
    required this.concernNum,
    required this.fansNum,
    required this.likeForumNum,
    required this.postNum,
    required this.portraitUrl,
    required this.id,
    required this.name,
    required this.intro,
    this.tbAge = '',
    this.margin,
  });

  void _openProfile(BuildContext context) {
    Navigator.pushNamed(context, PageRouter.user, arguments: id);
  }

  void _editProfile(BuildContext context) {
    Navigator.pushNamed(context, PageRouter.profileEdit);
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      margin: margin ??
          const EdgeInsets.fromLTRB(
            TiebananaMetrics.pageGutter,
            TiebananaMetrics.gapMd,
            TiebananaMetrics.pageGutter,
            0,
          ),
      decoration: BoxDecoration(
        borderRadius: TiebananaMetrics.brXl,
        boxShadow: tokens.cardShadow,
      ),
      child: Material(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brXl,
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double w = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final bool inlineRight = w >= 700;
            final bool narrowPhone = w < 460;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: inlineRight ? 20 : 14,
                vertical: inlineRight ? 16 : 14,
              ),
              child: inlineRight
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: _mainInfo(
                            context,
                            tokens,
                            textTheme,
                            showChevron: false,
                          ),
                        ),
                        const SizedBox(width: 20),
                        _statsBox(tokens, textTheme, expandItems: false),
                        const SizedBox(width: 14),
                        _editButton(context, tokens, textTheme),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _mainInfo(
                                context,
                                tokens,
                                textTheme,
                                showChevron: narrowPhone,
                              ),
                            ),
                            if (narrowPhone) ...<Widget>[
                              const SizedBox(width: 8),
                              _editButton(context, tokens, textTheme,
                                  compact: true),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _statsBox(tokens, textTheme,
                                  expandItems: true),
                            ),
                            if (!narrowPhone) ...<Widget>[
                              const SizedBox(width: 12),
                              _editButton(context, tokens, textTheme),
                            ],
                          ],
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _mainInfo(
    BuildContext context,
    TiebananaTokens tokens,
    TextTheme textTheme, {
    required bool showChevron,
  }) {
    final String metaLine = tbAge.trim().isNotEmpty
        ? 'ID $id · 吧龄 ${tbAge.trim()}'
        : 'ID $id';
    return InkWell(
      borderRadius: TiebananaMetrics.brLg,
      onTap: () => _openProfile(context),
      child: Row(
        children: <Widget>[
          Avatar(
            userId: id,
            imgUrl: portraitUrl,
            height: TiebananaMetrics.avatarXl,
            width: TiebananaMetrics.avatarXl,
            onTap: () => _openProfile(context),
          ),
          const SizedBox(width: TiebananaMetrics.gapSm + 1),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metaLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: tokens.textTertiary,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                if (intro.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    intro,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showChevron) ...<Widget>[
            const SizedBox(width: TiebananaMetrics.gapXs),
            Icon(
              Icons.chevron_right_outlined,
              size: 20,
              color: tokens.textTertiary,
            ),
          ],
        ],
      ),
    );
  }

  /// 一字排开的四项统计（始终 4 列同行，不折成 2×2）。
  Widget _statsBox(
    TiebananaTokens tokens,
    TextTheme textTheme, {
    required bool expandItems,
  }) {
    final List<MapEntry<String, String>> items = <MapEntry<String, String>>[
      MapEntry<String, String>('关注', concernNum),
      MapEntry<String, String>('粉丝', fansNum),
      MapEntry<String, String>('关注的吧', likeForumNum),
      MapEntry<String, String>('帖子', postNum),
    ];

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: expandItems ? MainAxisSize.max : MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < items.length; i++) ...<Widget>[
              if (i > 0)
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: tokens.line,
                ),
              expandItems
                  ? Expanded(
                      child: _statCell(
                          tokens, textTheme, items[i].key, items[i].value),
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 74),
                      child: _statCell(
                          tokens, textTheme, items[i].key, items[i].value),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCell(
      TiebananaTokens tokens, TextTheme textTheme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              fontSize: 10.5,
              color: tokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _editButton(
    BuildContext context,
    TiebananaTokens tokens,
    TextTheme textTheme, {
    bool compact = false,
  }) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: tokens.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _editProfile(context),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 11,
            vertical: 7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.edit_outlined, size: 14, color: tokens.textSecondary),
              if (!compact) ...<Widget>[
                const SizedBox(width: 5),
                Text(
                  '编辑资料',
                  style: textTheme.labelMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
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
