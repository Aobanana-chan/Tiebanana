import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/core/diagnostics/app_log.dart';
import 'package:tiebanana/features/message/state/notification_time.dart';
import 'package:tiebanana/features/message/widgets/broadcast_feed_card.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/skeleton.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';

/// 聚合「吧广播」信息流。
///
/// 版式对齐官方：按日期分组、跨吧卡片、分享 / 评论 / 点赞数；
/// 发布仍在网页版完成。
class BroadcastFeedPage extends StatefulWidget {
  const BroadcastFeedPage({super.key});

  @override
  State<BroadcastFeedPage> createState() => _BroadcastFeedPageState();
}

class _BroadcastFeedPageState extends State<BroadcastFeedPage> {
  final List<TiebaBroadcastItem> _items = <TiebaBroadcastItem>[];
  bool _loading = true;
  bool _refreshing = false;
  Object? _error;

  TiebaNotificationApi? get _api {
    try {
      final TiebaApi api = Global.tiebaAPI;
      return api is TiebaNotificationApi ? api as TiebaNotificationApi : null;
    } catch (_) {
      return null;
    }
  }

  bool get _unsupported => _api == null;

  bool get _loggedIn {
    try {
      return Global.tiebaAPI.isLogin;
    } catch (_) {
      return false;
    }
  }

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
      if (mounted) {
        setState(() {
          _loading = false;
          _error = StateError('当前后端不支持吧广播');
        });
      }
      _refreshing = false;
      return;
    }
    try {
      final List<TiebaBroadcastItem> items =
          await api.getBroadcastFeed(limit: 80);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _loading = false;
        _error = null;
      });
    } catch (error, stack) {
      AppLog.shared.error('message.broadcast_feed_failed', error, stack);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    } finally {
      _refreshing = false;
    }
  }

  void _openItem(TiebaBroadcastItem item) {
    final String? threadId = item.threadId;
    if (threadId == null || threadId.isEmpty) return;
    Navigator.pushNamed(
      context,
      PageRouter.threadPage,
      arguments: ThreadPageRouterData(kz: threadId, pid: null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        backgroundColor: tokens.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: tokens.textPrimary,
        title: const Text('吧广播'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _body(context),
        ),
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
        body: '吧广播需要登录后同步',
        primaryLabel: '去登录',
        onPrimary: () => Navigator.pushNamed(context, PageRouter.login),
      );
    }
    if (!_loggedIn) {
      return StateView(
        icon: Icons.person_outline,
        title: '登录后才能看吧广播',
        body: '吧广播需要登录后同步',
        primaryLabel: '去登录',
        onPrimary: () => Navigator.pushNamed(context, PageRouter.login),
      );
    }
    if (_loading && _items.isEmpty) return const _FeedSkeleton();
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
      return StateView(
        icon: Icons.campaign_outlined,
        title: '还没有吧广播',
        body: '关注的吧发布广播后会出现在这里',
        primaryLabel: '刷新',
        primaryIcon: Icons.refresh,
        onPrimary: () => _load(refresh: true),
      );
    }

    final List<Object> rows = <Object>[];
    String? lastDay;
    for (final TiebaBroadcastItem item in _items) {
      final DateTime? time = item.publishTime;
      if (time != null) {
        final String day = broadcastDayLabel(time);
        if (day != lastDay) {
          rows.add(day);
          lastDay = day;
        }
      }
      rows.add(item);
    }

    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: TiebananaMetrics.gapMd),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: rows.length,
        itemBuilder: (BuildContext context, int index) {
          final Object row = rows[index];
          if (row is String) return _DayHeader(day: row);
          final TiebaBroadcastItem item = row as TiebaBroadcastItem;
          return BroadcastFeedCard(
            item: item,
            onTap: () => _openItem(item),
          );
        },
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final String day;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Text(
        day,
        style: TextStyle(
          color: tokens.textTertiary,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: SkeletonBox(width: 92, height: 12),
        ),
        for (int i = 0; i < 3; i++)
          Container(
            margin: const EdgeInsets.fromLTRB(TiebananaMetrics.pageGutter, 0,
                TiebananaMetrics.pageGutter, 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: TiebananaMetrics.brLg,
              boxShadow: tokens.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                SkeletonBox(width: 210, height: 15),
                SizedBox(height: 10),
                SkeletonBox(height: 12),
                SizedBox(height: 6),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.8,
                  child: SkeletonBox(height: 12),
                ),
                SizedBox(height: 14),
                SkeletonBox(width: 120, height: 11),
              ],
            ),
          ),
      ],
    );
  }
}
