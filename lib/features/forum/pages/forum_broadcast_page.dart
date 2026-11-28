import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';
import 'package:tiebanana/features/forum/widgets/broadcast_card.dart';
import 'package:tiebanana/features/forum/widgets/broadcast_quota_sheet.dart';
import 'package:tiebanana/features/message/services/official_notify_pages.dart';
import 'package:tiebanana/shared/layout/app_breakpoints.dart';
import 'package:tiebanana/shared/layout/page_wrap.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/broadcast_image_lightbox.dart';
import 'package:tiebanana/shared/widgets/desktop_panel.dart';
import 'package:tiebanana/shared/widgets/desktop_shell.dart';
import 'package:tiebanana/shared/widgets/skeleton.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';
import 'package:tiebanana/shared/widgets/tiebanana_refresh_indicator.dart';

/// 吧广播历史页：原生只读 `getForumBroadcastList`，发布交给 H5。
///
/// 移动端保留紧凑吧信息条 + 单列历史；桌面宽屏（`>= 720dp`）纳入
/// [DesktopShellFrame] 与 [PageWrap]，左栏停靠吧档案与配额卡，右栏展示历史列表。
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

  String get _displayForumName {
    final String name = widget.data.forumName.trim();
    if (name.isEmpty) return '贴吧';
    return name.endsWith('吧') ? name : '$name吧';
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

  void _openZoom(TiebaBroadcastItem item, {bool desktop = false}) {
    showBroadcastImageLightbox(
      context,
      url: item.picUrl,
      title: item.title,
      forumName: _displayForumName,
      desktop: desktop,
    );
  }

  void _openForumHome() {
    final String raw = widget.data.forumName.trim();
    if (raw.isEmpty) return;
    Navigator.pushNamed(context, PageRouter.forumHome, arguments: raw);
  }

  Future<void> _openQuota({bool wide = false}) async {
    final TiebaBroadcastQuota? quota = _quota;
    if (quota == null) return;
    await showBroadcastQuotaSheet(context, quota, wide: wide);
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
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        if (width >= AppBreakpoints.compactMax) {
          return _buildDesktop(context, width);
        }
        return Scaffold(
          backgroundColor: TiebananaTokens.of(context).bg,
          appBar: _appBar(context),
          body: _narrow(context),
        );
      },
    );
  }

  AppBar _appBar(BuildContext context) {
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
        if (canPublish && _items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: () => _openQuota(wide: false),
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
        Expanded(child: _body(context, desktop: false)),
      ],
    );
  }

  Widget _buildDesktop(BuildContext context, double width) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final bool twoCol = width >= AppBreakpoints.mediumMax;
    final double dockWidth = width >= 1100 ? 288 : 264;
    final double colGap = width >= 1100 ? 16 : 14;
    final String sub = _items.isNotEmpty
        ? '$_displayForumName · 历史公告归档 · 已加载 ${_items.length} 条'
        : '$_displayForumName · 历史公告归档';

    return DesktopShellFrame(
      title: '$_displayForumName · 吧广播',
      subtitle: '官方广播与吧务通知',
      activeTab: -1,
      onRefresh: () => _load(refresh: true),
      child: PageWrap(
        maxWidth: AppBreakpoints.pageMaxWidth,
        bottomPadding: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DesktopPageHeader(
              title: '吧广播',
              subtitle: sub,
              tools: <Widget>[
                if (widget.data.forumName.trim().isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: _openForumHome,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tokens.textSecondary,
                      side: BorderSide(color: tokens.line),
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                    icon: const Icon(Icons.forum_outlined, size: 13.5),
                    label: const Text('进入吧主页'),
                  ),
              ],
            ),
            if (twoCol)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: dockWidth,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildDesktopDock(context),
                      ),
                    ),
                    SizedBox(width: colGap),
                    Expanded(child: _body(context, desktop: true)),
                  ],
                ),
              )
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildCompactStrip(context),
                    const SizedBox(height: 12),
                    Expanded(child: _body(context, desktop: true)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopDock(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TiebaBroadcastQuota? quota = _quotaFailed ? null : _quota;
    final bool hasQuota = quota != null;

    return DesktopPanel(
      borderRadius: TiebananaMetrics.brXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color.alphaBlend(
                    tokens.primaryContainer.withValues(alpha: 0.62),
                    tokens.surface,
                  ),
                  Color.alphaBlend(
                    tokens.primaryContainer.withValues(alpha: 0.16),
                    tokens.surface,
                  ),
                  tokens.surface,
                ],
              ),
              border: Border(bottom: BorderSide(color: tokens.line)),
            ),
            child: Row(
              children: <Widget>[
                _ForumAvatar(
                  name: _displayForumName,
                  avatar: widget.data.forumAvatar,
                  size: 52,
                  radius: 15,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _displayForumName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (hasQuota) ...<Widget>[
                  _QuotaCard(quota: quota),
                  const SizedBox(height: 12),
                  if (quota.canPublish) ...<Widget>[
                    SizedBox(
                      height: 40,
                      child: FilledButton.icon(
                        onPressed: _openPublishDirect,
                        icon: const Icon(Icons.open_in_new_rounded, size: 15),
                        label: const Text('去网页版发布'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 32,
                      child: OutlinedButton(
                        onPressed: () => _openQuota(wide: true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: tokens.textSecondary,
                          side: BorderSide(color: tokens.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('查看配额详情'),
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: tokens.fill,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        quota.total <= 0 ? '当前没有吧广播额度' : '本月吧广播次数已用完',
                        style: TextStyle(
                          color: tokens.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.fill,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '只读浏览模式',
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '当前账号在该吧暂无吧务发布额度，仅展示本吧已发布的历史广播记录。',
                          style: TextStyle(
                            color: tokens.textSecondary,
                            fontSize: 11.5,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Divider(height: 1, color: tokens.line),
                const SizedBox(height: 11),
                _DockKv(label: '已加载条数', value: '${_items.length} 条'),
                const SizedBox(height: 6),
                const _DockKv(label: '排序方式', value: '服务端默认顺序'),
                const SizedBox(height: 11),
                Text(
                  '发布与编辑在贴吧网页版完成；本页仅做历史归档与阅读数静默刷新。',
                  style: TextStyle(
                    color: tokens.textTertiary,
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStrip(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TiebaBroadcastQuota? quota = _quotaFailed ? null : _quota;
    return DesktopPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          _ForumAvatar(
            name: _displayForumName,
            avatar: widget.data.forumAvatar,
            size: 40,
            radius: 11,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _displayForumName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  quota == null
                      ? '官方广播与吧务通知'
                      : '本月剩余 ${quota.remaining} / ${quota.total} 次',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (quota != null && quota.canPublish) ...<Widget>[
            const SizedBox(width: 10),
            FilledButton(
              onPressed: _openPublishDirect,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('去网页版发布'),
            ),
          ],
        ],
      ),
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

  Widget _wrapDesktopState(bool desktop, Widget child) {
    if (!desktop) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: DesktopPanel(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: child,
      ),
    );
  }

  Widget _body(BuildContext context, {required bool desktop}) {
    if (_unsupported) {
      return _wrapDesktopState(
        desktop,
        const StateView(
          icon: Icons.campaign_outlined,
          title: '当前版本暂不支持吧广播',
          body: '切换到支持吧广播的贴吧后端后再试',
        ),
      );
    }
    if (_notLoggedIn) {
      return _wrapDesktopState(
        desktop,
        StateView(
          icon: Icons.person_outline,
          title: '登录后才能看吧广播',
          body: '吧广播历史需要登录后读取',
          primaryLabel: '去登录',
          onPrimary: () => Navigator.pushNamed(context, PageRouter.login),
        ),
      );
    }
    if (_loading && _items.isEmpty) {
      return _BroadcastSkeleton(desktop: desktop);
    }
    if (_error != null && _items.isEmpty) {
      return _wrapDesktopState(
        desktop,
        StateView(
          icon: Icons.wifi_off_outlined,
          title: '广播没有加载出来',
          body: '检查网络后重试',
          primaryLabel: '重试',
          primaryIcon: Icons.refresh,
          onPrimary: () => _load(),
        ),
      );
    }
    if (_items.isEmpty) {
      final bool canPublish = _quota?.canPublish ?? false;
      return _wrapDesktopState(
        desktop,
        StateView(
          icon: Icons.campaign_outlined,
          title: '这个吧还没有吧广播',
          body: '吧务发布后会出现在这里',
          primaryLabel: canPublish ? '发吧广播' : null,
          onPrimary: canPublish ? () => _openQuota(wide: desktop) : null,
        ),
      );
    }
    final bool showFooter = _loadingMore ||
        _moreError != null ||
        _error != null ||
        !_hasMore ||
        desktop;
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
          padding: EdgeInsets.only(
            left: desktop ? 0 : TiebananaMetrics.pageGutter,
            right: desktop ? 0 : TiebananaMetrics.pageGutter,
            top: desktop ? 0 : 6,
            bottom: desktop ? 24 : TiebananaMetrics.gapMd,
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _items.length + (showFooter ? 1 : 0),
          itemBuilder: (BuildContext context, int index) {
            if (index >= _items.length) {
              return _footer(context, desktop: desktop);
            }
            final TiebaBroadcastItem item = _items[index];
            return BroadcastCard(
              item: item,
              desktop: desktop,
              onOpenThread: () => _openThread(item),
              onZoomImage: () => _openZoom(item, desktop: desktop),
            );
          },
        ),
      ),
    );
  }

  Widget _footer(BuildContext context, {required bool desktop}) {
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
    if (_hasMore && desktop) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: TextButton(
            onPressed: _nextPage,
            child: Text(
              '点击加载更多',
              style: TextStyle(
                color: tokens.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          desktop ? '没有更多历史广播了' : '没有更多了',
          style: TextStyle(color: tokens.textTertiary, fontSize: 11),
        ),
      ),
    );
  }
}

class _DockKv extends StatelessWidget {
  const _DockKv({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(color: tokens.textTertiary, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
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
        color: tokens.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('本月吧广播',
              style: TextStyle(
                  color: tokens.textTertiary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text('${quota.remaining}',
                  style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ])),
              const SizedBox(width: 6),
              Text('次可用',
                  style: TextStyle(color: tokens.textTertiary, fontSize: 11.5)),
            ],
          ),
          if (total > 0) ...<Widget>[
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: tokens.fill,
                valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
              ),
            ),
          ],
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('已用 $used 次',
                  style: TextStyle(
                    color: tokens.textTertiary,
                    fontSize: 11,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  )),
              Text('共 $total 次',
                  style: TextStyle(
                    color: tokens.textTertiary,
                    fontSize: 11,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _BroadcastSkeleton extends StatelessWidget {
  const _BroadcastSkeleton({this.desktop = false});

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: desktop ? 0 : 6),
      children: <Widget>[
        for (int i = 0; i < 3; i++)
          Container(
            margin: EdgeInsets.fromLTRB(
              desktop ? 0 : TiebananaMetrics.pageGutter,
              0,
              desktop ? 0 : TiebananaMetrics.pageGutter,
              9,
            ),
            padding: const EdgeInsets.all(TiebananaMetrics.cardPadding),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: TiebananaMetrics.brLg,
              boxShadow: tokens.cardShadow,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
