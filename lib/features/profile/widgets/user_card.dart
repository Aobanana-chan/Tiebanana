import 'package:flutter/material.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';

/// 「我的」页顶部的用户信息卡。
///
/// 对应概念图 `design/mockups/user.html`（方向 A）的 `.ucard`：
/// 圆角大卡浮在页面底色上，从上到下是「头像 + 昵称 + 签名 + 右侧箭头」，
/// 再用一条细描边分隔四项统计（关注 / 粉丝 / 关注的吧 / 帖子）。
///
/// 颜色全部取自 [TiebananaTokens] 的语义色。
class UserCard extends StatelessWidget {
  /// 关注数
  final String concernNum;

  /// 粉丝数
  final String fansNum;

  /// 关注的吧数量
  final String likeForumNum;

  /// 帖子数
  final String postNum;
  final String portraitUrl;
  final String id;
  final String name;
  final String intro;

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
  });

  /// 点头像或整张卡片头部 → 进自己的用户主页。
  void _openProfile(BuildContext context) {
    Navigator.pushNamed(context, PageRouter.user, arguments: id);
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        TiebananaMetrics.pageGutter,
        TiebananaMetrics.gapMd,
        TiebananaMetrics.pageGutter,
        0,
      ),
      decoration: BoxDecoration(
        borderRadius: TiebananaMetrics.brXl,
        boxShadow: tokens.cardShadow,
      ),
      // 用 Material 承载卡片表面，行内水波纹由圆角裁剪。
      child: Material(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brXl,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(TiebananaMetrics.gapLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _header(context, tokens, textTheme),
              _stats(tokens, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(
      BuildContext context, TiebananaTokens tokens, TextTheme textTheme) {
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
          // Avatar 自带 5 的右外边距，这里补 8，合计 13，与概念图的 .utop 间距一致。
          const SizedBox(width: TiebananaMetrics.gapSm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium
                      ?.copyWith(color: tokens.textPrimary),
                ),
                const SizedBox(height: TiebananaMetrics.gapXs),
                Text(
                  intro,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall
                      ?.copyWith(color: tokens.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: TiebananaMetrics.gapSm),
          Icon(
            Icons.chevron_right_outlined,
            size: 20,
            color: tokens.textTertiary,
          ),
        ],
      ),
    );
  }

  /// 四项统计：等分四列，数字在上、标签在下，整行用一条细描边与头部隔开。
  Widget _stats(TiebananaTokens tokens, TextTheme textTheme) {
    final List<MapEntry<String, String>> items = <MapEntry<String, String>>[
      MapEntry<String, String>('关注', concernNum),
      MapEntry<String, String>('粉丝', fansNum),
      MapEntry<String, String>('关注的吧', likeForumNum),
      MapEntry<String, String>('帖子', postNum),
    ];
    return Container(
      margin: const EdgeInsets.only(top: TiebananaMetrics.gapMd + 2),
      padding: const EdgeInsets.only(top: TiebananaMetrics.gapMd + 1),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.line)),
      ),
      child: Row(
        children: items
            .map((MapEntry<String, String> e) =>
                Expanded(child: _statItem(tokens, textTheme, e.key, e.value)))
            .toList(),
      ),
    );
  }

  Widget _statItem(
      TiebananaTokens tokens, TextTheme textTheme, String label, String value) {
    return InkWell(
      borderRadius: TiebananaMetrics.brSm,
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TiebananaMetrics.gapXs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: TiebananaMetrics.gapXs - 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(color: tokens.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
