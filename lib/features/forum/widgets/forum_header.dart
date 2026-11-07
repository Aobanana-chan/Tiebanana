import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/content/tieba_parser.dart';

///吧页面的头部信息卡。
///
///对应概念图 `design/mockups/forum.html`（方向 A）的 `.fhead`：
///圆角 22 的浮动卡片，从左到右是吧头像、吧名 + 等级、关注 / 帖子数、
///经验进度条、等级文案，最右侧是签到 / 关注按钮。
class ForumHeader extends StatefulWidget {
  final String fName; //吧名
  final String levelupScore; //升到下一级所需的总经验
  final bool isLike;
  final bool isSigned;
  final String fid;
  final String curScore; //现在的经验
  final String avatar; //吧头像 widget.info.avatar ?? widget.info.fShareImg!
  final String levelId;
  final String levelName;

  ///关注数（原始计数，展示时按 W / K / KW 缩写）。
  final String memberNum;

  ///帖子数（原始计数，展示时按 W / K / KW 缩写）。
  final String postNum;

  const ForumHeader({
    super.key,
    required this.fName,
    required this.levelupScore,
    required this.isLike,
    required this.isSigned,
    required this.fid,
    required this.curScore,
    required this.avatar,
    required this.levelId,
    required this.levelName,
    this.memberNum = "0",
    this.postNum = "0",
  });

  @override
  _ForumHeaderState createState() => _ForumHeaderState();
}

class _ForumHeaderState extends State<ForumHeader> {
  late bool _isLike;
  late bool isSignIn;
  late String levelupScore;
  late String curScore;
  late String levelId;
  late String levelName;

  @override
  void initState() {
    super.initState();
    _isLike = widget.isLike;
    isSignIn = widget.isSigned;
    levelupScore = widget.levelupScore;
    curScore = widget.curScore;
    levelId = widget.levelId;
    levelName = widget.levelName;
  }

  ///把原始计数缩写成「12.86W / 2341.2W」形态，解析失败时原样返回。
  String _count(String raw) {
    final int? value = int.tryParse(raw);
    if (value == null) {
      return raw;
    }
    return TiebaParser.numberConvertString(value);
  }

  ///当前等级的经验进度（0–1）。经验上限缺失或为 0 时按 0 处理。
  double get _progress {
    final int max = int.tryParse(levelupScore) ?? 0;
    final int cur = int.tryParse(curScore) ?? 0;
    if (max <= 0) {
      return 0;
    }
    return (cur / max).clamp(0.0, 1.0);
  }

  ///距下一级还差多少经验。
  int get _scoreGap {
    final int max = int.tryParse(levelupScore) ?? 0;
    final int cur = int.tryParse(curScore) ?? 0;
    return (max - cur) < 0 ? 0 : max - cur;
  }

  Future<void> _onSign() async {
    final SignResult res = await Global.tiebaAPI.signOneForum(widget.fName);
    Fluttertoast.showToast(msg: res.message);
    if (!mounted) {
      return;
    }
    setState(() {
      if (res.levelupScore.isNotEmpty) {
        levelupScore = res.levelupScore;
      }
      curScore = (int.parse(curScore) + (int.tryParse(res.bonusPoint) ?? 0))
          .toString();
      if (res.ok) {
        isSignIn = true;
      }
    });
  }

  Future<void> _onFollow() async {
    await Global.tiebaAPI.favoForum(widget.fid, widget.fName);
    if (!mounted) {
      return;
    }
    setState(() {
      _isLike = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? metaStyle =
        textTheme.labelSmall?.copyWith(color: tokens.textTertiary);

    return Container(
      margin: const EdgeInsets.fromLTRB(
          TiebananaMetrics.pageGutter, TiebananaMetrics.gapMd,
          TiebananaMetrics.pageGutter, 0),
      padding: const EdgeInsets.all(TiebananaMetrics.cardPadding),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brXl,
        boxShadow: tokens.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _ForumAvatar(url: widget.avatar, tokens: tokens),
          const SizedBox(width: TiebananaMetrics.gapMd),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        "${widget.fName}吧",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium
                            ?.copyWith(color: tokens.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      "Lv.$levelId",
                      style: metaStyle?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: TiebananaMetrics.gapXs - 1),
                Text(
                  "关注 ${_count(widget.memberNum)} · 帖子 ${_count(widget.postNum)}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: metaStyle,
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: TiebananaMetrics.brPill,
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    backgroundColor: tokens.surfaceAlt,
                    valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _levelLine(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: metaStyle,
                ),
              ],
            ),
          ),
          const SizedBox(width: TiebananaMetrics.gapMd),
          _actionButton(context, tokens, textTheme),
        ],
      ),
    );
  }

  String _levelLine() {
    final String name = levelName.isEmpty ? "" : "$levelName · ";
    return "$name距下一级 $_scoreGap 经验";
  }

  Widget _actionButton(
      BuildContext context, TiebananaTokens tokens, TextTheme textTheme) {
    final bool signed = _isLike && isSignIn;
    final String label = !_isLike ? "关注" : (isSignIn ? "已签到" : "签到");
    return Material(
      color: signed ? tokens.surfaceAlt : tokens.primaryContainer,
      borderRadius: TiebananaMetrics.brPill,
      child: InkWell(
        borderRadius: TiebananaMetrics.brPill,
        onTap: signed
            ? null
            : () {
                if (!_isLike) {
                  _onFollow();
                } else {
                  _onSign();
                }
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          child: Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: signed ? tokens.textTertiary : tokens.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

///吧头像：圆角 14 的方形（与概念图一致），加载失败时退化为一个吧字占位。
class _ForumAvatar extends StatelessWidget {
  const _ForumAvatar({required this.url, required this.tokens});

  final String url;
  final TiebananaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: ClipRRect(
        borderRadius: TiebananaMetrics.brCtl,
        child: url.isEmpty
            ? _placeholder()
            : ExtendedImage.network(
                url,
                fit: BoxFit.cover,
                cache: true,
                loadStateChanged: (ExtendedImageState state) {
                  if (state.extendedImageLoadState == LoadState.failed) {
                    return _placeholder();
                  }
                  return null;
                },
              ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: tokens.surfaceAlt,
      child: Icon(Icons.forum_outlined,
          size: 24, color: tokens.textTertiary),
    );
  }
}
