import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/moderation/widgets/moderation_actions.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/content/tieba_parser.dart';

/// 贴页共用的小部件与文案工具。
///
/// 对应概念图 `design/mockups/thread.html`：楼层号药丸、独立赞 / 踩按钮、
/// 卡片右上角「更多」、楼中楼头等都在这里，首楼卡与楼层卡只负责排版。

/// 相对时间。空值 / 非法值返回空串，调用方据此省略分隔符。
String threadTimeText(String? seconds) {
  final int? stamp = int.tryParse(seconds ?? '');
  if (stamp == null || stamp <= 0) {
    return '';
  }
  return TiebaParser.getPostTime(intTime: stamp);
}

/// IP 属地。使用接口返回的 IP 属地字段。
String threadLocationText(String? raw) {
  final String value = (raw ?? '').trim();
  if (value.isEmpty) {
    return '';
  }
  if (value.startsWith('IP')) {
    return value;
  }
  return 'IP属地：$value';
}

/// 「2小时前 · IP属地：上海」，缺项时自动省略中间的点。
String threadMetaText(String time, String? location) {
  final String where = threadLocationText(location);
  if (time.isEmpty) {
    return where;
  }
  if (where.isEmpty) {
    return time;
  }
  return '$time · $where';
}

/// 计数缩写：大于 9999 时使用 App 统一的 W / K 口径。
String threadCountText(int value) {
  if (value <= 9999) {
    return '$value';
  }
  return TiebaParser.numberConvertString(value);
}

/// 过滤掉没有可用地址的图片段。
///
/// 投票楼层的第一段常常是 `linkImage` 之类的占位图片，`src` 为空。
/// 这里剔除空地址和非 http(s) 地址的图片，用户正常的配图原样保留。
List<TiebaPostContent> contentWithoutUnusableImages(
    List<TiebaPostContent> content) {
  return content.where((TiebaPostContent element) {
    if (element is! TiebaImageContent) {
      return true;
    }
    final String src = element.displaySrc.trim();
    if (src.isEmpty) {
      return false;
    }
    final Uri? uri = Uri.tryParse(src);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }).toList();
}

/// 元信息占满右侧内容列，可换行，不与右上角赞踩争夺宽度。
class ThreadPostMeta extends StatelessWidget {
  const ThreadPostMeta(
      {super.key, required this.time, required this.ipLocation});

  final String time;
  final String ipLocation;

  @override
  Widget build(BuildContext context) {
    final String location = threadLocationText(ipLocation);
    final TextStyle? style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: TiebananaTokens.of(context).textTertiary,
        );
    return Wrap(
      spacing: TiebananaMetrics.gapSm,
      runSpacing: TiebananaMetrics.gapXXs,
      children: <Widget>[
        if (time.isNotEmpty) Text(time, style: style),
        if (location.isNotEmpty) Text(location, style: style),
      ],
    );
  }
}

/// 作者身份行：窄屏时徽章自然换行。
class ThreadAuthorLine extends StatelessWidget {
  const ThreadAuthorLine({
    super.key,
    required this.name,
    required this.level,
    required this.icons,
    this.isOp = false,
    this.forumRole,
    this.isDeleted = false,
  });

  final String name;
  final String? level;
  final List<Widget> icons;
  final bool isOp;
  final TiebaForumRole? forumRole;

  /// 该楼层 / 回复已从服务端删除，当前展示的是缓存内容。
  final bool isDeleted;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: TiebananaMetrics.gapXs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          name,
          // 名字最多两行：极长昵称在第二行末尾省略，
          // 既保住可读性，也限制作者行高度。
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: TiebananaTokens.of(context).textPrimary,
              ),
        ),
        if (isOp || forumRole != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (isOp) const ThreadOpBadge(compact: true),
              if (isOp && forumRole != null) const SizedBox(width: 4),
              if (forumRole != null) ThreadForumRoleBadge(role: forumRole!),
            ],
          ),
        if (isDeleted) const ThreadDeletedBadge(),
        ThreadLevelText(level: level),
        ...icons.take(2),
      ],
    );
  }
}

/// 「已删除」徽章：提示该楼层已从服务端删除，当前展示缓存内容。
class ThreadDeletedBadge extends StatelessWidget {
  const ThreadDeletedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: tokens.fill,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tokens.danger.withValues(alpha: 0.4)),
      ),
      child: Text(
        '已删除',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: tokens.danger,
              height: 1,
            ),
      ),
    );
  }
}

/// 楼层作者投的阵营徽章（蓝方 / 红方）。
///
/// 服务端把阵营做成一张主题图案（`PbContent.type == 52`）。图案本身
/// 位图直接显示会发糊且不跟随明暗主题；界面只把它作为识别依据：
/// 首次取到后按主色判定红/蓝并缓存，之后用普通组件 chip 渲染。
class ThreadVoteBadge extends StatefulWidget {
  const ThreadVoteBadge({super.key, required this.badge, this.height = 24});

  final TiebaVoteBadgeContent badge;
  final double height;

  @override
  State<ThreadVoteBadge> createState() => _ThreadVoteBadgeState();
}

class _ThreadVoteBadgeState extends State<ThreadVoteBadge> {
  /// 官方徽章可见内容约 90×48。
  static const double _visibleAspect = 90 / 48;

  bool? _blue;
  bool _ready = false;
  String _resolvedUrl = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant ThreadVoteBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.badge != widget.badge) {
      _resolvedUrl = '';
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final String url = widget.badge.imageUrl;
    if (url == _resolvedUrl) return;
    _resolvedUrl = url;

    if (url.isEmpty) {
      if (mounted) {
        setState(() {
          _blue = null;
          _ready = true;
        });
      }
      return;
    }

    final bool? cached = _VoteBadgeSide.cached(url);
    if (_VoteBadgeSide.isCached(url)) {
      if (mounted) {
        setState(() {
          _blue = cached;
          _ready = true;
        });
      }
      return;
    }

    if (mounted) setState(() => _ready = false);
    final bool? side = await _VoteBadgeSide.of(url);
    if (!mounted || url != _resolvedUrl) return;
    setState(() {
      _blue = side;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final bool blue = _blue == true;
    final bool known = _ready && _blue != null;
    final Color accent = known
        ? (blue ? tokens.pollBlue : tokens.pollRed)
        : tokens.textSecondary;
    final Color background = known
        ? (blue ? tokens.pollBlueContainer : tokens.pollRedContainer)
        : tokens.fill;
    final String label = known ? (blue ? '蓝方' : '红方') : '已投';

    return Semantics(
      label: known ? '投了$label' : '已参与投票',
      image: false,
      child: Container(
        width: widget.height * _visibleAspect,
        height: widget.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(TiebananaMetrics.radiusXs),
          border: Border.all(color: accent.withValues(alpha: .35)),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
                height: 1,
                fontSize: widget.height * 0.5,
              ),
        ),
      ),
    );
  }
}

/// 根据阵营图案的主色判定红 / 蓝，并按 URL 缓存。
///
/// 图案是「蓝方 / 红方」两种固定模板，蓝底的蓝分量明显高于红分量；
/// 只统计高饱和像素，排除白字和透明边。
class _VoteBadgeSide {
  _VoteBadgeSide._();

  static final Map<String, bool?> _cache = <String, bool?>{};
  static final Map<String, Future<bool?>> _pending = <String, Future<bool?>>{};

  static bool isCached(String url) => _cache.containsKey(url);

  static bool? cached(String url) => _cache[url];

  static Future<bool?> of(String url) {
    if (_cache.containsKey(url)) {
      return Future<bool?>.value(_cache[url]);
    }
    return _pending.putIfAbsent(url, () => _load(url));
  }

  static Future<bool?> _load(String url) {
    final Completer<bool?> completer = Completer<bool?>();
    final ImageStream stream =
        NetworkImage(url).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;

    void finish(bool? side) {
      _cache[url] = side;
      _pending.remove(url);
      if (!completer.isCompleted) completer.complete(side);
    }

    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        stream.removeListener(listener);
        _classifyAndFinish(info.image.clone(), finish);
      },
      onError: (Object error, StackTrace? stackTrace) {
        stream.removeListener(listener);
        finish(null);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  static Future<void> _classifyAndFinish(
      ui.Image image, void Function(bool?) finish) async {
    try {
      finish(await _classify(image));
    } catch (_) {
      finish(null);
    } finally {
      image.dispose();
    }
  }

  static Future<bool?> _classify(ui.Image image) async {
    final ByteData? data =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;
    final Uint8List bytes = data.buffer.asUint8List();

    int r = 0, b = 0, n = 0;
    int sr = 0, sb = 0, sn = 0;
    for (int i = 0; i + 3 < bytes.length; i += 4) {
      if (bytes[i + 3] < 200) continue;
      final int pr = bytes[i];
      final int pg = bytes[i + 1];
      final int pb = bytes[i + 2];
      r += pr;
      b += pb;
      n++;
      final int max = math.max(pr, math.max(pg, pb));
      final int min = math.min(pr, math.min(pg, pb));
      if (max - min > 30) {
        sr += pr;
        sb += pb;
        sn++;
      }
    }
    if (n == 0) return null;
    final double red = sn > 0 ? sr / sn : r / n;
    final double blueValue = sn > 0 ? sb / sn : b / n;
    return blueValue > red;
  }
}

/// 楼层号药丸。楼主楼层用主色容器，其余用填充色。
class ThreadFloorTag extends StatelessWidget {
  const ThreadFloorTag({super.key, required this.floor, this.isOp = false});

  final String? floor;
  final bool isOp;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final String text = (floor == null || floor!.isEmpty) ? '-' : '$floor楼';
    return Container(
      constraints: const BoxConstraints(minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: isOp ? tokens.primaryContainer : tokens.fill,
        borderRadius: TiebananaMetrics.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1,
              color: isOp ? tokens.onPrimaryContainer : tokens.textSecondary,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// 「楼主」徽章。
class ThreadOpBadge extends StatelessWidget {
  const ThreadOpBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 16 : 18),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: tokens.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '楼主',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tokens.onPrimaryContainer,
                  height: 1,
                ),
          ),
        ],
      ),
    );
  }
}

/// 当前吧的管理身份；小吧为明亮蓝色，吧主为明亮红色。
class ThreadForumRoleBadge extends StatelessWidget {
  const ThreadForumRoleBadge({super.key, required this.role});

  final TiebaForumRole role;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final bool manager = role == TiebaForumRole.manager;
    final Color background = manager
        ? tokens.managerBadgeBackground
        : tokens.assistantBadgeBackground;
    final Color foreground = manager
        ? tokens.managerBadgeForeground
        : tokens.assistantBadgeForeground;
    return Container(
      constraints: const BoxConstraints(minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        manager ? '吧主' : '小吧',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: foreground,
              height: 1,
            ),
      ),
    );
  }
}

/// 等级文案。概念图里楼层作者使用一行等宽感的小字。
class ThreadLevelText extends StatelessWidget {
  const ThreadLevelText({super.key, required this.level});

  final String? level;

  @override
  Widget build(BuildContext context) {
    final String? value = level;
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Text(
      'Lv.$value',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: tokens.textTertiary,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
  }
}

/// 赞 / 踩的状态与网络请求。
///
/// 底部回复条的主题赞踩共用同一个实例；
/// 其他楼层各自持有一个实例。
class ThreadAgreeController extends ChangeNotifier {
  ThreadAgreeController({
    required this.postId,
    required this.threadId,
    required this.objType,
    this.forumId,
    required this.agreeNum,
    required this.disagreeNum,
    required String hasAgree,
    required int agreeType,
  })  : liked = hasAgree == '1' && agreeType == 2,
        disliked = hasAgree == '1' && agreeType == 5;

  final String postId;
  final String threadId;
  final String? forumId;

  /// 1 = 楼层，2 = 楼中楼，3 = 主题。
  final int objType;

  int agreeNum;
  int disagreeNum;
  bool liked;
  bool disliked;
  bool busy = false;

  Future<void> toggleLike() async {
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      if (liked) {
        await Global.tiebaAPI
            .agreePost(postId, threadId, objType, forumId: forumId, opType: 1);
        liked = false;
        agreeNum = _decrease(agreeNum);
      } else {
        if (disliked) {
          await Global.tiebaAPI.agreePost(
            postId,
            threadId,
            objType,
            forumId: forumId,
            agreeType: 5,
            opType: 1,
          );
          disliked = false;
          disagreeNum = _decrease(disagreeNum);
        }
        await Global.tiebaAPI
            .agreePost(postId, threadId, objType, forumId: forumId);
        liked = true;
        agreeNum += 1;
      }
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> toggleDislike() async {
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      if (disliked) {
        await Global.tiebaAPI.agreePost(
          postId,
          threadId,
          objType,
          forumId: forumId,
          agreeType: 5,
          opType: 1,
        );
        disliked = false;
        disagreeNum = _decrease(disagreeNum);
      } else {
        if (liked) {
          await Global.tiebaAPI.agreePost(postId, threadId, objType,
              forumId: forumId, opType: 1);
          liked = false;
          agreeNum = _decrease(agreeNum);
        }
        await Global.tiebaAPI.agreePost(
          postId,
          threadId,
          objType,
          forumId: forumId,
          agreeType: 5,
        );
        disliked = true;
        disagreeNum += 1;
      }
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  static int _decrease(int value) => value <= 0 ? 0 : value - 1;
}

/// 楼层卡右上角的独立赞 / 踩按钮。
class ThreadVoteBar extends StatefulWidget {
  const ThreadVoteBar({
    super.key,
    this.controller,
    required this.postId,
    required this.threadId,
    required this.objType,
    required this.agreeNum,
    required this.disagreeNum,
    required this.hasAgree,
    required this.agreeType,
    this.forumId,
    this.showDislike = true,
  });

  /// 给定时不归本组件管理生命周期。
  final ThreadAgreeController? controller;

  final String postId;
  final String threadId;
  final String? forumId;
  final int objType;
  final int agreeNum;
  final int disagreeNum;
  final String hasAgree;
  final int agreeType;
  final bool showDislike;

  @override
  State<ThreadVoteBar> createState() => _ThreadVoteBarState();
}

class _ThreadVoteBarState extends State<ThreadVoteBar> {
  late ThreadAgreeController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    _ownsController = widget.controller == null;
    _controller = widget.controller ??
        ThreadAgreeController(
          postId: widget.postId,
          threadId: widget.threadId,
          objType: widget.objType,
          forumId: widget.forumId,
          agreeNum: widget.agreeNum,
          disagreeNum: widget.disagreeNum,
          hasAgree: widget.hasAgree,
          agreeType: widget.agreeType,
        );
  }

  @override
  void didUpdateWidget(covariant ThreadVoteBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.postId != widget.postId ||
        oldWidget.threadId != widget.threadId ||
        oldWidget.objType != widget.objType ||
        oldWidget.forumId != widget.forumId) {
      if (_ownsController) {
        _controller.dispose();
      }
      _bind();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _tap(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return SizedBox(
          height: 28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _VoteButton(
                icon: _controller.liked
                    ? Icons.thumb_up_alt_rounded
                    : Icons.thumb_up_alt_outlined,
                count: _controller.agreeNum,
                active: _controller.liked,
                tooltip: _controller.liked ? '取消点赞' : '点赞',
                onTap: _controller.busy
                    ? null
                    : () => _tap(_controller.toggleLike),
              ),
              if (widget.showDislike) ...<Widget>[
                const SizedBox(width: 4),
                _VoteButton(
                  icon: _controller.disliked
                      ? Icons.thumb_down_alt_rounded
                      : Icons.thumb_down_alt_outlined,
                  count: _controller.disagreeNum,
                  active: _controller.disliked,
                  tooltip: _controller.disliked ? '取消点踩' : '点踩',
                  onTap: _controller.busy
                      ? null
                      : () => _tap(_controller.toggleDislike),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.icon,
    required this.count,
    required this.active,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final int count;
  final bool active;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final Color foreground = active ? tokens.primary : tokens.textSecondary;
    final RoundedRectangleBorder shape = RoundedRectangleBorder(
      borderRadius: TiebananaMetrics.brSm,
      side: BorderSide(
        color: active
            ? tokens.primary.withValues(alpha: 0.35)
            : Colors.transparent,
      ),
    );
    return Semantics(
      button: true,
      selected: active,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: active ? tokens.primaryContainer : tokens.fill,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: shape,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, size: 13, color: foreground),
                  const SizedBox(width: 2),
                  Text(
                    threadCountText(count),
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: foreground,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures()
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

/// 底部回复条里的圆形赞 / 踩按钮：图标在上、数量在下。
class ThreadLikeAction extends StatelessWidget {
  const ThreadLikeAction(
      {super.key, required this.controller, this.isDislike = false});

  final ThreadAgreeController controller;
  final bool isDislike;

  Future<void> _onTap(BuildContext context) async {
    try {
      if (isDislike) {
        await controller.toggleDislike();
      } else {
        await controller.toggleLike();
      }
    } catch (e) {
      if (!context.mounted) return;
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final bool active = isDislike ? controller.disliked : controller.liked;
        return Semantics(
          button: true,
          selected: active,
          child: Tooltip(
            message:
                isDislike ? (active ? '取消点踩' : '点踩') : (active ? '取消点赞' : '点赞'),
            child: Material(
              color: active ? tokens.primaryContainer : tokens.fill,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: controller.busy ? null : () => _onTap(context),
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        isDislike
                            ? (active
                                ? Icons.thumb_down_alt_rounded
                                : Icons.thumb_down_alt_outlined)
                            : active
                                ? Icons.thumb_up_alt_rounded
                                : Icons.thumb_up_alt_outlined,
                        size: 17,
                        color: active
                            ? tokens.onPrimaryContainer
                            : tokens.textSecondary,
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 40,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            threadCountText(isDislike
                                ? controller.disagreeNum
                                : controller.agreeNum),
                            maxLines: 1,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? tokens.onPrimaryContainer
                                  : tokens.textSecondary,
                              height: 1,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 卡片右上角「更多」：收藏 / 分享 / 举报 / 拉黑。
///
/// 举报目标与作者身份由卡片传入，楼中楼使用自己的楼层 ID。
class ThreadMoreButton extends StatelessWidget {
  const ThreadMoreButton({
    super.key,
    required this.threadId,
    required this.postId,
    this.storedNotifier,
    this.size = 26,
    this.iconSize = 18,
    this.authorId = '',
    this.authorName = '',
    this.portrait = '',
    this.summary = '',
    this.source = '',
    this.reportKind = TiebaReportKind.reply,
  });

  final String threadId;
  final String postId;
  final ValueNotifier<bool>? storedNotifier;
  final double size;
  final double iconSize;
  final String authorId, authorName, portrait, summary, source;
  final TiebaReportKind reportKind;

  Future<void> _onSelected(BuildContext context, String value) async {
    switch (value) {
      case 'store':
        final uid = AccountStore.currentUid ?? '';
        try {
          await Global.tiebaAPI.threadAddStore(threadId, postId);
          await Global.threadCache.setStored(uid, threadId, true,
              keepLongTerm: Global.setting.markedCache ?? true);
          if (!context.mounted) return;
          storedNotifier?.value = true;
          Fluttertoast.showToast(msg: '已收藏到本楼');
        } catch (e) {
          if (!context.mounted) return;
          Fluttertoast.showToast(msg: e.toString());
        }
        return;
      case 'share':
        await Clipboard.setData(ClipboardData(
          text: 'https://tieba.baidu.com/p/$threadId?pid=$postId',
        ));
        if (!context.mounted) return;
        Fluttertoast.showToast(msg: '链接已复制');
        return;
      case 'report':
        await openReportPage(
            context,
            TiebaReportTarget(
                kind: reportKind,
                userId: authorId,
                name: authorName,
                portrait: portrait,
                threadId: threadId,
                postId: postId,
                summary: summary,
                source: source));
        return;
      case 'block':
        await showBlockSettings(context, uid: authorId, name: authorName);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return PopupMenuButton<String>(
      tooltip: '更多',
      position: PopupMenuPosition.under,
      color: tokens.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: TiebananaMetrics.brLg),
      onSelected: (String value) => _onSelected(context, value),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _menuItem(context, 'store', Icons.star_border_rounded, '收藏'),
        _menuItem(context, 'share', Icons.ios_share_rounded, '分享'),
        if ((int.tryParse(postId) ?? 0) > 0 ||
            reportKind == TiebaReportKind.thread &&
                (int.tryParse(threadId) ?? 0) > 0)
          _menuItem(context, 'report', Icons.flag_outlined,
              '举报${reportKind == TiebaReportKind.thread ? '帖子' : '回复'}'),
        if (!isOwnModerationTarget(authorId) &&
            (int.tryParse(authorId) ?? 0) > 0)
          _menuItem(context, 'block', Icons.block_rounded, '拉黑作者'),
      ],
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: tokens.fill,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.more_vert_rounded,
          size: iconSize,
          color: tokens.textSecondary,
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    BuildContext context,
    String value,
    IconData icon,
    String label,
  ) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return PopupMenuItem<String>(
      value: value,
      height: 42,
      child: Row(
        children: <Widget>[
          Icon(icon, size: 17, color: tokens.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: tokens.textPrimary),
          ),
        ],
      ),
    );
  }
}
