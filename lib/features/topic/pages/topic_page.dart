import 'package:tiebanana/features/compose/models/thread_compose_route_data.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/topic/data/topic_cache.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/skeleton.dart';
import 'package:tiebanana/shared/widgets/state_view.dart';
import 'package:tiebanana/shared/content/thread_summary.dart';
import 'package:tiebanana/shared/content/tieba_parser.dart';
import 'package:url_launcher/url_launcher.dart';

/// 话题页。
///
/// 只走原生界面：头图 / 话题简介 / 吧友热议 / 发帖。
/// 数据由 [TiebaApi.getTopicDetail] 与 [TiebaApi.getTopicThreads] 提供。
class TopicPageRoute extends StatefulWidget {
  const TopicPageRoute({super.key, required this.data, this.api});

  final TopicPageRouterData data;

  /// 测试注入；为空时使用 [Global.tiebaAPI]。
  final TiebaApi? api;

  @override
  State<TopicPageRoute> createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPageRoute> {
  final ScrollController _scroll = ScrollController();
  TiebaApi get _api => widget.api ?? Global.tiebaAPI;

  TiebaTopicDetail? _detail;
  List<TiebaThreadInfo> _threads = <TiebaThreadInfo>[];
  bool _loading = false;
  bool _loadingMore = false;
  bool _switchingSort = false;
  bool _hasMore = true;
  String _lastId = '';
  int _page = 1;
  int _sort = 1;
  Object? _error;
  Object? _moreError;
  bool _scrolled = false;
  bool _descExpanded = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _searching = false;
  String _query = '';

  /// 列表代次：排序 / 刷新后旧请求的迟到回包直接丢弃。
  int _listVersion = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    final TopicCacheEntry? cached =
        widget.api == null ? TopicCache.get(widget.data.name, _sort) : null;
    if (cached != null) {
      _detail = cached.detail;
      _threads = cached.threads.toList();
      _hasMore = cached.hasMore;
      _lastId = cached.lastId;
      _page = cached.page;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (cached != null) {
        _load(refresh: true, silent: true);
      } else {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final ScrollPosition position = _scroll.position;
    if (!_switchingSort && position.pixels >= position.maxScrollExtent - 420) {
      _loadMore();
    }
    final bool scrolled = position.pixels > 120;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
  }

  Future<void> _load({bool refresh = false, bool silent = false}) async {
    if (_loading || _switchingSort) return;
    final bool keep = refresh && _detail != null;
    final int version = ++_listVersion;
    setState(() {
      _loading = true;
      _switchingSort = false;
      _loadingMore = false;
      _error = null;
      _moreError = null;
      if (!keep) {
        _detail = null;
        _threads = <TiebaThreadInfo>[];
        _hasMore = true;
        _lastId = '';
        _page = 1;
      }
    });

    try {
      final TiebaTopicDetail detail = await _api.getTopicDetail(
        name: widget.data.name,
        topicId: widget.data.topicId,
        fid: widget.data.fid,
        forumName: widget.data.forumName,
      );
      if (!mounted || version != _listVersion) return;
      setState(() => _detail = detail);

      final TiebaTopicThreadPage page = await _api.getTopicThreads(
        name: detail.name.isEmpty ? widget.data.name : detail.name,
        topicId: detail.id,
        page: 1,
        sort: _sort,
      );
      if (!mounted || version != _listVersion) return;
      setState(() {
        _threads = page.threads;
        _hasMore = page.hasMore;
        _lastId = page.lastId;
        _page = page.currentPage;
        _loading = false;
        _error = null;
      });
      _putCache();
    } catch (error) {
      if (!mounted || version != _listVersion) return;
      setState(() {
        _loading = false;
        if (!keep) _error = error;
      });
      if (keep && !silent) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('刷新失败，保留当前内容'),
            duration: Duration(seconds: 2),
          ));
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loading ||
        _loadingMore ||
        _switchingSort ||
        !_hasMore ||
        _detail == null) {
      return;
    }
    final int version = _listVersion;
    final int sort = _sort;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final TiebaTopicThreadPage page = await _api.getTopicThreads(
        name: _detail!.name,
        topicId: _detail!.id,
        page: _page + 1,
        sort: sort,
        lastId: _lastId,
      );
      if (!mounted || version != _listVersion || sort != _sort) return;
      final Set<String> seen = _threads.map((t) => t.id).toSet();
      setState(() {
        _threads = <TiebaThreadInfo>[
          ..._threads,
          ...page.threads.where((t) => seen.add(t.id)),
        ];
        _hasMore = page.hasMore && page.threads.isNotEmpty;
        _lastId = page.lastId;
        _page = page.currentPage;
        _loadingMore = false;
      });
      _putCache();
    } catch (error) {
      if (!mounted || version != _listVersion || sort != _sort) return;
      setState(() {
        _loadingMore = false;
        _moreError = error;
      });
    }
  }

  Future<void> _changeSort(int sort) async {
    if (_sort == sort || _switchingSort || _detail == null) return;
    final int previous = _sort;
    final List<TiebaThreadInfo> previousThreads = _threads;
    final bool previousHasMore = _hasMore;
    final String previousLastId = _lastId;
    final int previousPage = _page;
    final int version = ++_listVersion;
    final TopicCacheEntry? cached =
        widget.api == null ? TopicCache.get(widget.data.name, sort) : null;
    setState(() {
      _sort = sort;
      _switchingSort = true;
      _loading = false;
      _moreError = null;
      _loadingMore = false;
      if (cached != null) {
        _threads = cached.threads.toList();
        _hasMore = cached.hasMore;
        _lastId = cached.lastId;
        _page = cached.page;
      }
    });
    try {
      final TiebaTopicThreadPage page = await _api.getTopicThreads(
        name: _detail!.name,
        topicId: _detail!.id,
        page: 1,
        sort: sort,
      );
      if (!mounted || version != _listVersion) return;
      setState(() {
        _threads = page.threads;
        _hasMore = page.hasMore;
        _lastId = page.lastId;
        _page = page.currentPage;
        _switchingSort = false;
        _error = null;
      });
      _putCache();
    } catch (_) {
      if (!mounted || version != _listVersion) return;
      setState(() {
        _sort = previous;
        _threads = previousThreads;
        _hasMore = previousHasMore;
        _lastId = previousLastId;
        _page = previousPage;
        _switchingSort = false;
      });
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('切换失败，已保留原列表'),
          duration: Duration(seconds: 2),
        ));
    }
  }

  void _putCache() {
    if (widget.api != null || _detail == null) return;
    TopicCache.put(
      name: widget.data.name,
      sort: _sort,
      detail: _detail!,
      threads: _threads,
      hasMore: _hasMore,
      lastId: _lastId,
      page: _page,
    );
  }

  Future<void> _openCompose() async {
    if (!_api.isLogin) {
      await Navigator.pushNamed(context, PageRouter.login);
      if (!mounted || !_api.isLogin) return;
    }
    final String fid = widget.data.fid;
    final String forumName = widget.data.forumName.isNotEmpty
        ? widget.data.forumName
        : (_detail?.forumName ?? '');
    if (fid.isEmpty || fid == '0' || forumName.isEmpty) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('请从吧内进入话题后再发帖'),
          duration: Duration(seconds: 2),
        ));
      return;
    }
    if (!mounted) return;
    await Navigator.pushNamed(
      context,
      PageRouter.threadCompose,
      arguments: ThreadComposeRouteData(
        fid: fid,
        forumName: forumName,
        topicId: _detail?.id ?? widget.data.topicId,
        topicName: _detail?.name ?? widget.data.name,
      ),
    );
  }

  void _openSearch() {
    setState(() => _searching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchFocus.unfocus();
    setState(() {
      _searching = false;
      _query = '';
      _searchController.clear();
    });
  }

  List<TiebaThreadInfo> get _visibleThreads {
    final String query = _query.trim().toLowerCase();
    if (query.isEmpty) return _threads;
    return _threads.where((TiebaThreadInfo thread) {
      final String text = '${thread.title} ${_contentText(thread)} '
              '${thread.author.name} ${thread.fname}'
          .toLowerCase();
      return text.contains(query);
    }).toList();
  }

  String _contentText(TiebaThreadInfo thread) {
    final StringBuffer buffer = StringBuffer();
    for (final TiebaPostContent content in thread.firstPostContent) {
      if (content is TiebaTextContent) {
        buffer.write(content.text);
      } else if (content is TiebaTopicContent) {
        buffer.write(content.text);
      } else if (content is TiebaLinkContent) {
        buffer.write(content.text);
      } else if (content is TiebaAtContent) {
        buffer.write(content.text);
      }
      if (buffer.length > 300) break;
    }
    return buffer.toString();
  }

  String get _topicUrl {
    final String name = _detail?.name ?? widget.data.name;
    final String id = _detail?.id ?? widget.data.topicId;
    return Uri.https('tieba.baidu.com', '/hottopic/browse/hottopic', {
      if (id.isNotEmpty) 'topic_id': id,
      'topic_name': name,
    }).toString();
  }

  Future<void> _share() async {
    if (_detail == null) return;
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final String url = _topicUrl;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: tokens.surface,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '分享话题',
                    style: Theme.of(sheetContext)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: tokens.textPrimary),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.link_rounded, color: tokens.primary),
                title: const Text('复制话题链接'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await Clipboard.setData(ClipboardData(text: url));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(const SnackBar(
                      content: Text('话题链接已复制'),
                      duration: Duration(seconds: 2),
                    ));
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.open_in_browser_rounded, color: tokens.primary),
                title: const Text('在浏览器打开'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final bool ok = await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                  if (!mounted || ok) return;
                  ScaffoldMessenger.of(context)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(const SnackBar(
                      content: Text('没有可用的浏览器'),
                      duration: Duration(seconds: 2),
                    ));
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _searchField(TiebananaTokens tokens) {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      autofocus: true,
      textInputAction: TextInputAction.search,
      onChanged: (String value) => setState(() => _query = value),
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(color: tokens.textPrimary),
      decoration: InputDecoration(
        hintText: '在话题内筛选',
        hintStyle: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: tokens.textTertiary),
        border: InputBorder.none,
        isDense: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final bool hasHero = _detail != null;
    final bool searching = _searching;
    final bool transparentBar = hasHero && !_scrolled && !searching;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final PreferredSizeWidget appBar = AppBar(
      backgroundColor: transparentBar ? Colors.transparent : tokens.bar,
      foregroundColor: transparentBar ? tokens.onImage : tokens.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: transparentBar
          ? SystemUiOverlayStyle.light
          : (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark),
      leading: IconButton(
        tooltip: searching ? '退出搜索' : '返回',
        onPressed: searching ? _closeSearch : () => Navigator.maybePop(context),
        icon: Icon(
          searching
              ? Icons.arrow_back_rounded
              : Icons.arrow_back_ios_new_rounded,
          size: 20,
        ),
      ),
      title: searching
          ? _searchField(tokens)
          : (_scrolled && hasHero
              ? Text(
                  '话题',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: tokens.textPrimary),
                )
              : null),
      actions: searching
          ? <Widget>[
              if (_query.isNotEmpty)
                IconButton(
                  tooltip: '清除',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.close_rounded, size: 21),
                ),
            ]
          : <Widget>[
              IconButton(
                tooltip: '搜索',
                onPressed: _openSearch,
                icon: const Icon(Icons.search_rounded, size: 22),
              ),
              IconButton(
                tooltip: '分享',
                onPressed: _share,
                icon: const Icon(Icons.ios_share_rounded, size: 21),
              ),
            ],
    );

    return Scaffold(
      backgroundColor: tokens.bg,
      extendBodyBehindAppBar: hasHero,
      appBar: appBar,
      floatingActionButton: hasHero && _detail != null
          ? FloatingActionButton.extended(
              onPressed: _openCompose,
              backgroundColor: tokens.accentFill,
              foregroundColor: tokens.accentOn,
              elevation: 2,
              shape:
                  RoundedRectangleBorder(borderRadius: TiebananaMetrics.brLg),
              icon: const Icon(Icons.edit_outlined, size: 19),
              label: const Text('发帖'),
            )
          : null,
      body: _body(context, tokens),
    );
  }

  Widget _body(BuildContext context, TiebananaTokens tokens) {
    if (_detail == null) {
      if (_error != null) {
        return Center(
          child: StateView(
            icon: Icons.wifi_off_rounded,
            title: '话题没加载出来',
            body: '检查一下网络，或者稍后再试',
            primaryLabel: '重试',
            primaryIcon: Icons.refresh,
            onPrimary: _load,
          ),
        );
      }
      return const _TopicSkeleton();
    }

    final TiebaTopicDetail detail = _detail!;
    final bool filtering = _query.trim().isNotEmpty;
    final List<TiebaThreadInfo> visible = _visibleThreads;
    return RefreshIndicator(
      color: tokens.primary,
      backgroundColor: tokens.surface,
      edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
      onRefresh: () => _load(refresh: true),
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(child: _TopicHeader(detail: detail)),
          SliverToBoxAdapter(child: _description(context, detail)),
          SliverToBoxAdapter(child: _section(context, detail, visible.length)),
          if (_switchingSort)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: ClipRRect(
                  borderRadius: TiebananaMetrics.brPill,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: tokens.primary,
                    backgroundColor: tokens.fill,
                  ),
                ),
              ),
            ),
          if (_loading && _threads.isEmpty)
            const SliverToBoxAdapter(child: _FeedSkeleton())
          else if (_error != null && _threads.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: StateView(
                icon: Icons.wifi_off_rounded,
                title: '讨论没加载出来',
                body: '话题还在，帖子列表暂时不可用',
                primaryLabel: '重试',
                primaryIcon: Icons.refresh,
                onPrimary: _load,
              ),
            )
          else if (visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: filtering && _threads.isNotEmpty
                  ? StateView(
                      icon: Icons.search_off_rounded,
                      title: '已加载的帖子里没有匹配',
                      body: _hasMore ? '继续加载更多帖子后再试' : '换个关键词，或者看看其他排序',
                      primaryLabel: _hasMore ? '继续加载' : null,
                      primaryIcon: Icons.expand_more_rounded,
                      onPrimary: _hasMore ? _loadMore : null,
                    )
                  : StateView(
                      icon: Icons.forum_outlined,
                      title: '还没有相关帖子',
                      body: '换个排序，或者稍后再来看看',
                      primaryLabel: '刷新',
                      primaryIcon: Icons.refresh,
                      onPrimary: () => _load(refresh: true),
                    ),
            )
          else
            SliverList.builder(
              itemCount: visible.length,
              itemBuilder: (BuildContext context, int index) {
                final TiebaThreadInfo thread = visible[index];
                return ThreadSummary(
                  firstPostContent: thread.firstPostContent,
                  author: thread.author,
                  createTime: thread.createTime,
                  latestTime: thread.lastTimeInt,
                  tid: thread.id,
                  fname: thread.fname,
                  viewNum: thread.viewNum,
                  title: thread.title,
                  agreeNum: thread.agreeNum,
                  disagreeNum: thread.disagreeNum,
                  replyNum: thread.replyNum,
                  dismissible: false,
                );
              },
            ),
          if (_loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            )
          else if (_moreError != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: TextButton.icon(
                    onPressed: _loadMore,
                    icon: const Icon(Icons.refresh, size: 17),
                    label: const Text('加载失败，点击重试'),
                  ),
                ),
              ),
            )
          else if (!_hasMore && visible.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    '没有更多了',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: tokens.textTertiary),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }

  Widget _description(BuildContext context, TiebaTopicDetail detail) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
        boxShadow: tokens.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.tag_rounded, size: 15, color: tokens.primary),
          const SizedBox(width: 5),
          Text(
            '话题简介',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: tokens.textTertiary),
          ),
          const Spacer(),
          if (detail.hasPostNum)
            Text(
              '${_count(detail.postNum)} 帖子',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: tokens.textTertiary),
            ),
        ]),
        const SizedBox(height: 6),
        _descriptionBody(
            context, detail.hasDescription ? detail.desc : '这个话题还没有简介'),
      ]),
    );
  }

  /// 简介默认 3 行；内容超出时在卡片底部压一层半透明黑渐变 + 「显示全部」。
  Widget _descriptionBody(BuildContext context, String desc) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextStyle style = Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tokens.textSecondary,
              height: 1.55,
            ) ??
        TextStyle(color: tokens.textSecondary, height: 1.55);

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: desc, style: style),
        maxLines: 3,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: constraints.maxWidth);
      final bool overflows = painter.didExceedMaxLines;
      painter.dispose();

      if (_descExpanded) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(desc, style: style),
          const SizedBox(height: 2),
          Center(child: _descToggle(context, expanded: true)),
        ]);
      }
      if (!overflows) return Text(desc, style: style);

      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ShaderMask(
          shaderCallback: (Rect bounds) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              tokens.onImage,
              tokens.onImage,
              tokens.onImage.withValues(alpha: 0),
            ],
            stops: const <double>[0, .84, 1],
          ).createShader(bounds),
          blendMode: BlendMode.dstIn,
          child: Text(
            desc,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        const SizedBox(height: 2),
        Center(child: _descToggle(context, expanded: false)),
      ]);
    });
  }

  Widget _descToggle(BuildContext context, {required bool expanded}) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Material(
      color: tokens.fill,
      borderRadius: TiebananaMetrics.brPill,
      child: InkWell(
        borderRadius: TiebananaMetrics.brPill,
        onTap: () => setState(() => _descExpanded = expanded ? false : true),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(
              expanded ? '收起' : '显示全部',
              style: TextStyle(
                color: tokens.primary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: tokens.primary,
            ),
          ]),
        ),
      ),
    );
  }

  Widget _section(
      BuildContext context, TiebaTopicDetail detail, int visibleCount) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final bool filtering = _query.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 8),
      child: Row(children: [
        Expanded(
          child: Row(children: [
            Flexible(
              child: Text(
                filtering ? '搜索结果' : '吧友热议',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: tokens.textPrimary),
              ),
            ),
            if (filtering || detail.hasPostNum) ...[
              const SizedBox(width: 8),
              Text(
                filtering ? '$visibleCount 条' : _count(detail.postNum),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: tokens.textTertiary),
              ),
            ],
          ]),
        ),
        _SortPill(
          label: '热门',
          selected: _sort == 1,
          enabled: !_switchingSort,
          onTap: () => _changeSort(1),
        ),
        const SizedBox(width: 6),
        _SortPill(
          label: '最新',
          selected: _sort == 2,
          enabled: !_switchingSort,
          onTap: () => _changeSort(2),
        ),
      ]),
    );
  }

  String _count(String raw) {
    final int value = int.tryParse(raw) ?? 0;
    return value > 0 ? TiebaParser.numberConvertString(value) : raw;
  }
}

class _TopicHeader extends StatelessWidget {
  const _TopicHeader({required this.detail});
  final TiebaTopicDetail detail;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final double top = MediaQuery.of(context).padding.top + kToolbarHeight;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: top + 168,
      child: Stack(fit: StackFit.expand, children: [
        if (detail.hasCover)
          ExtendedImage.network(
            detail.cover,
            fit: BoxFit.cover,
            cache: true,
            loadStateChanged: (ExtendedImageState state) {
              if (state.extendedImageLoadState == LoadState.failed) {
                return _fallback(tokens, dark);
              }
              return null;
            },
          )
        else
          _fallback(tokens, dark),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                tokens.imageScrim.withValues(alpha: .48),
                tokens.imageScrim.withValues(alpha: .08),
                tokens.imageScrim.withValues(alpha: .68),
              ],
              stops: const [0, .45, 1],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, top + 4, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tokens.onImage.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '话题',
                  style: TextStyle(
                      color: tokens.onImage,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '#${detail.name}#',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.onImage,
                  fontSize: 25,
                  height: 1.18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              _metrics(context),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _fallback(TiebananaTokens tokens, bool dark) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.primary,
            tokens.primary.withValues(alpha: .62),
            tokens.surfaceHigh,
          ],
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 26, top: 42),
          child: Text(
            '#',
            style: TextStyle(
              fontSize: 210,
              height: .8,
              fontWeight: FontWeight.w800,
              color: tokens.accentOn.withValues(alpha: .10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _metrics(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final List<(String, String)> items = <(String, String)>[
      if (detail.hasHot) ('热度', detail.hotValue),
      if (detail.hasDiscuss) ('讨论', detail.discussNum),
      if (detail.hasPostNum) ('帖子', detail.postNum),
    ];
    if (items.isEmpty) {
      return Text(
        '吧友正在讨论',
        style: TextStyle(
            color: tokens.onImage.withValues(alpha: .7), fontSize: 11.5),
      );
    }
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(Container(
          width: 3,
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: tokens.onImage.withValues(alpha: .54),
            shape: BoxShape.circle,
          ),
        ));
      }
      children.add(Text.rich(TextSpan(children: [
        TextSpan(
          text: '${items[i].$1} ',
          style: TextStyle(
              color: tokens.onImage.withValues(alpha: .7), fontSize: 11),
        ),
        TextSpan(
          text: _format(items[i].$2),
          style: TextStyle(
              color: tokens.onImage,
              fontSize: 11.5,
              fontWeight: FontWeight.w600),
        ),
      ])));
    }
    return Row(children: children);
  }

  String _format(String raw) {
    final int value = int.tryParse(raw) ?? 0;
    return value > 0 ? TiebaParser.numberConvertString(value) : raw;
  }
}

class _SortPill extends StatelessWidget {
  const _SortPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Opacity(
      opacity: enabled ? 1 : .55,
      child: Material(
        color: selected ? tokens.primaryContainer : tokens.surfaceAlt,
        borderRadius: TiebananaMetrics.brPill,
        child: InkWell(
          borderRadius: TiebananaMetrics.brPill,
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected
                        ? tokens.onPrimaryContainer
                        : tokens.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicSkeleton extends StatelessWidget {
  const _TopicSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        SkeletonBox(height: 190, radius: TiebananaMetrics.radiusXl),
        SizedBox(height: 12),
        SkeletonBox(height: 84, radius: TiebananaMetrics.radiusLg),
        SizedBox(height: 14),
        SkeletonBox(width: 120, height: 18),
        SizedBox(height: 12),
        _SkeletonCard(),
        SizedBox(height: 10),
        _SkeletonCard(),
      ],
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(children: [
        _SkeletonCard(),
        SizedBox(height: 10),
        _SkeletonCard(),
      ]),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: TiebananaMetrics.brLg,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const SkeletonBox(width: 30, height: 30, radius: 15),
          const SizedBox(width: 8),
          const Expanded(child: SkeletonBox(height: 12)),
          const SizedBox(width: 40),
        ]),
        const SizedBox(height: 14),
        const SkeletonBox(height: 15),
        const SizedBox(height: 8),
        const SkeletonBox(height: 12),
        const SizedBox(height: 12),
        const SkeletonBox(height: 78, radius: TiebananaMetrics.radiusSm),
      ]),
    );
  }
}
