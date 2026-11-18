import 'package:flutter/material.dart';
import 'package:tiebanana/shared/widgets/tiebanana_refresh_indicator.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';
import 'package:tiebanana/features/forum/widgets/broadcast_card.dart';
import 'package:tiebanana/features/forum/widgets/broadcast_quota_sheet.dart';
import 'package:tiebanana/features/message/services/official_notify_pages.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/skeleton.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';

/// 吧广播历史页：原生只读 `getForumBroadcastList`，发布交给 H5。
class ForumBroadcastPage extends StatefulWidget {
  const ForumBroadcastPage({super.key, required this.data});

  final ForumBroadcastRouteData data;

  @override
  State<ForumBroadcastPage> createState() => _ForumBroadcastPageState();
}

class _ForumBroadcastPageState extends State<ForumBroadcastPage> {
  final List<TiebaBroadcastItem> _items = <TiebaBroadcastItem>[];
  final Set<String> _pvRefreshed = <String>{};

  bool _loading = true;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _cursor = 0;
  Object? _error;
  Object? _moreError;
  TiebaBroadcastQuota? _quota;
  bool _quotaFailed = false;

  TiebaNotificationApi? get _api {
    try {
      final TiebaApi api = Global.tiebaAPI;
      return api is TiebaNotificationApi ? api as TiebaNotificationApi : null;
    } catch (_) {
      return null;
    }
  }

  bool get _unsupported => _api == null;

  bool get _notLoggedIn {
    final Object? error = _error;
    return error != null && error.toString().contains('未登录');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load({bool refresh = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!refresh && _items.isEmpty && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final TiebaNotificationApi? api = _api;
    if (api == null) {
      setState(() {
        _loading = false;
        _error = StateError('当前后端不支持吧广播');
      });
      _refreshing = false;
      return;
    }
    try {
      final TiebaBroadcastPage page = await api.getBroadcastHistory(
        forumId: widget.data.forumId,
        cursor: 0,
        count: 15,
      );
      if (!mounted) return;
      final Set<String> seen = <String>{};
      final List<TiebaBroadcastItem> items = <TiebaBroadcastItem>[
        for (final TiebaBroadcastItem item in page.items)
          if (seen.add(item.id)) item,
      ];
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _cursor = page.nextCursor != 0
            ? page.nextCursor
            : (items.isEmpty ? 0 : int.tryParse(items.last.id) ?? 0);
        _hasMore = page.hasMore;
        _loading = false;
        _error = null;
        _moreError = null;
      });
      _refreshPv(items);
    } catch (error, stack) {
      AppLog.shared.error('forum.broadcast_history_failed', error, stack);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    } finally {
      _refreshing = false;
    }
    _loadQuota();
  }

  Future<void> _loadQuota() async {
    final TiebaNotificationApi? api = _api;
    if (api == null) return;
    try {
      final TiebaBroadcastQuota? quota =
          await api.getBroadcastQuota(widget.data.forumId);
      if (!mounted) return;
      setState(() {
        _quota = quota;
        _quotaFailed = quota == null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _quota = null;
        _quotaFailed = true;
      });
    }
  }

  /// 阅读数静默刷新；失败保留旧值，不打扰列表。
  Future<void> _refreshPv(List<TiebaBroadcastItem> items) async {
    final TiebaNotificationApi? api = _api;
    if (api == null) return;
    final List<String> ids = <String>[
      for (final TiebaBroadcastItem item in items)
        if (item.hasThread && _pvRefreshed.add(item.id)) item.id,
    ];
    if (ids.isEmpty) return;
    try {
      final Map<String, int> pv = await api.refreshBroadcastPv(
        forumId: widget.data.forumId,
        bcastIds: ids,
      );
      if (!mounted || pv.isEmpty) return;
      setState(() {
        for (int i = 0; i < _items.length; i++) {
          final int? next = pv[_items[i].id];
          if (next != null) _items[i] = _items[i].copyWith(pv: next);
        }
      });
    } catch (error, stack) {
      AppLog.shared.error('forum.broadcast_pv_failed', error, stack);
    }
  }

  Future<void> _nextPage() async {
    if (_loading || _loadingMore || !_hasMore) return;
    final TiebaNotificationApi? api = _api;
    if (api == null) return;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final TiebaBroadcastPage page = await api.getBroadcastHistory(
        forumId: widget.data.forumId,
        cursor: _cursor,
        count: 15,
      );
      if (!mounted) return;
      final Set<String> existing =
          _items.map((TiebaBroadcastItem e) => e.id).toSet();
      final List<TiebaBroadcastItem> added = <TiebaBroadcastItem>[
        for (final TiebaBroadcastItem item in page.items)
          if (existing.add(item.id)) item,
      ];
      setState(() {
        _items.addAll(added);
        _cursor = page.nextCursor == 0 ? _cursor : page.nextCursor;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
      _refreshPv(added);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _moreError = error;
      });
    }
  }

  void _openThread(TiebaBroadcastItem item) {
    final String? threadId = item.threadId;
    if (threadId == null || threadId.isEmpty) return;
    Navigator.pushNamed(
      context,
      PageRouter.threadPage,
      arguments: ThreadPageRouterData(kz: threadId, pid: null),
    );
  }

  Future<void> _openQuota() async {
    final TiebaBroadcastQuota? quota = _quota;
    if (quota == null) return;
    await showBroadcastQuotaSheet(context, quota);
    if (!mounted) return;
    await _load(refresh: true);
  }

  Future<void> _openPublishDirect() async {
    await openBroadcastPublish(context);
    if (!mounted) return;
    await _load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= 900;
        return Scaffold(
          backgroundColor: TiebananaTokens.of(context).bg,
          appBar: _appBar(context, wide: wide),
          body: wide ? _wide(context) : _narrow(context),
        );
      },
    );
  }

  AppBar _appBar(BuildContext context, {required bool wide}) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final bool canPublish = _quota?.canPublish ?? false;
    return AppBar(
      backgroundColor: tokens.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: tokens.textPrimary,
      titleSpacing: 4,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('吧广播'),
          Text(
            '官方广播与吧务通知',
            style: TextStyle(
              color: tokens.textTertiary,
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        if (!wide && canPublish && _items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _openQuota,
              style: TextButton.styleFrom(
                backgroundColor: tokens.primaryContainer,
                foregroundColor: tokens.onPrimaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 32),
                shape: const StadiumBorder(),
              ),
              child: const Text('发吧广播',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }

  Widget _narrow(BuildContext context) {
    return Column(
      children: <Widget>[
        _forumStrip(context),
        Expanded(child: _body(context)),
      ],
    );
  }

  Widget _wide(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 300,
          child: Container(
            height: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: tokens.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _ForumAvatar(
                      name: widget.data.forumName,
                      avatar: widget.data.forumAvatar,
                      size: 42,
                      radius: 13,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.data.forumName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tokens.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '官方广播与吧务通知',
                            style: TextStyle(
                              color: tokens.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_quota != null) _QuotaCard(quota: _quota!),
                if (_quota != null && _quota!.canPublish) ...<Widget>[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: FilledButton(
                      onPressed: _openPublishDirect,
                      child: const Text('去发布'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '发布与编辑在贴吧网页版完成。这里只显示配额，不提供原生编辑器。',
                  style: TextStyle(
                    color: tokens.textTertiary,
                    fontSize: 10.5,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 18, 32, 0),
                child: _body(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _forumStrip(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TiebaBroadcastQuota? quota = _quota;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: Row(
        children: <Widget>[
          _ForumAvatar(
            name: widget.data.forumName,
            avatar: widget.data.forumAvatar,
            size: 36,
            radius: 11,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.data.forumName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  quota == null
                      ? '官方广播与吧务通知'
                      : '本月已用 ${quota.used} 次 · 共 ${quota.total} 次',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.textTertiary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          if (quota != null && !_quotaFailed)
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: tokens.fill,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                '剩余 ${quota.remaining} 次',
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_unsupported) {
      return const StateView(
        icon: Icons.campaign_outlined,
        title: '当前版本暂不支持吧广播',
        body: '切换到支持吧广播的贴吧后端后再试',
      );
    }
    if (_notLoggedIn) {
      return StateView(
        icon: Icons.person_outline,
        title: '登录后才能看吧广播',
        body: '吧广播历史需要登录后读取',
        primaryLabel: '去登录',
        onPrimary: () => Navigator.pushNamed(context, PageRouter.login),
      );
    }
    if (_loading && _items.isEmpty) return const _BroadcastSkeleton();
    if (_error != null && _items.isEmpty) {
      return StateView(
        icon: Icons.wifi_off_outlined,
        title: '广播没有加载出来',
        body: '检查网络后重试',
        primaryLabel: '重试',
        primaryIcon: Icons.refresh,
        onPrimary: () => _load(),
      );
    }
    if (_items.isEmpty) {
      final bool canPublish = _quota?.canPublish ?? false;
      return StateView(
        icon: Icons.campaign_outlined,
        title: '这个吧还没有吧广播',
        body: '吧务发布后会出现在这里',
        primaryLabel: canPublish ? '发吧广播' : null,
        onPrimary: canPublish ? _openQuota : null,
      );
    }
    final bool showFooter =
        _loadingMore || _moreError != null || _error != null || !_hasMore;
    return TiebananaRefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 160) {
            _nextPage();
          }
          return false;
        },
        child: ListView.builder(
          padding:
              const EdgeInsets.only(top: 6, bottom: TiebananaMetrics.gapMd),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _items.length + (showFooter ? 1 : 0),
          itemBuilder: (BuildContext context, int index) {
            if (index >= _items.length) {
              return _footer(context);
            }
            final TiebaBroadcastItem item = _items[index];
            return BroadcastCard(
              item: item,
              onOpenThread: () => _openThread(item),
            );
          },
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    if (_error != null && _items.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _load(refresh: true),
            child: Text(
              '刷新失败，点此重试',
              style: TextStyle(
                  color: tokens.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }
    if (_moreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _nextPage,
            child: Text(
              '加载失败，点此重试',
              style: TextStyle(
                  color: tokens.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          '没有更多了',
          style: TextStyle(color: tokens.textTertiary, fontSize: 10.5),
        ),
      ),
    );
  }
}

class _ForumAvatar extends StatelessWidget {
  const _ForumAvatar({
    required this.name,
    required this.avatar,
    required this.size,
    required this.radius,
  });

  final String name;
  final String avatar;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final String text = name.trim().isEmpty ? '吧' : name.trim().substring(0, 1);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: avatar.isEmpty
            ? Container(
                color: tokens.primaryContainer,
                alignment: Alignment.center,
                child: Text(
                  text,
                  style: TextStyle(
                    color: tokens.onPrimaryContainer,
                    fontSize: size * 0.36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            : Image.network(
                avatar,
                fit: BoxFit.cover,
                errorBuilder:
                    (BuildContext context, Object error, StackTrace? stack) {
                  return Container(
                    color: tokens.primaryContainer,
                    alignment: Alignment.center,
                    child: Text(
                      text,
                      style: TextStyle(
                        color: tokens.onPrimaryContainer,
                        fontSize: size * 0.36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({required this.quota});

  final TiebaBroadcastQuota quota;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final int used = quota.used < 0 ? 0 : quota.used;
    final int total = quota.total < 0 ? 0 : quota.total;
    final double progress =
        total <= 0 ? 0 : (used > total ? 1 : used / total).toDouble();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('本月吧广播',
              style: TextStyle(
                  color: tokens.textTertiary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text('${quota.remaining}',
                  style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1)),
              const SizedBox(width: 5),
              Text('次可用',
                  style: TextStyle(color: tokens.textTertiary, fontSize: 11)),
            ],
          ),
          if (total > 0) ...<Widget>[
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: tokens.fill,
                valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('已用 $used',
                  style: TextStyle(color: tokens.textTertiary, fontSize: 10.5)),
              Text('共 $total',
                  style: TextStyle(color: tokens.textTertiary, fontSize: 10.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BroadcastSkeleton extends StatelessWidget {
  const _BroadcastSkeleton();

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 6),
      children: <Widget>[
        for (int i = 0; i < 3; i++)
          Container(
            margin: const EdgeInsets.fromLTRB(
                TiebananaMetrics.pageGutter, 0, TiebananaMetrics.pageGutter, 9),
            padding: const EdgeInsets.all(TiebananaMetrics.cardPadding),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: TiebananaMetrics.brLg,
              boxShadow: tokens.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                SkeletonBox(width: 180, height: 14),
                SizedBox(height: 10),
                SkeletonBox(height: 11),
                SizedBox(height: 6),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.86,
                  child: SkeletonBox(height: 11),
                ),
                SizedBox(height: 6),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.55,
                  child: SkeletonBox(height: 11),
                ),
                SizedBox(height: 12),
                SkeletonBox(width: 150, height: 10),
              ],
            ),
          ),
      ],
    );
  }
}
