import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 吧页页签条。
///
/// 页签由协议数据驱动（`frs_main_tab_list`，实现方已筛成可用项）。横向可滑，
/// 溢出时右侧给「更多」入口，点开底部面板列出全部。
class ForumTabBar extends StatefulWidget {
  /// 固定高度（含内边距），吸顶时按它算 extent。
  static const double height = 50;

  final List<TiebaForumTab> tabs;
  final int index;
  final ValueChanged<int> onSelect;

  const ForumTabBar({
    super.key,
    required this.tabs,
    required this.index,
    required this.onSelect,
  });

  @override
  State<ForumTabBar> createState() => _ForumTabBarState();
}

class _ForumTabBarState extends State<ForumTabBar> {
  final ScrollController _scroll = ScrollController();
  final List<GlobalKey> _keys = <GlobalKey>[];
  bool _overflow = false;

  @override
  void initState() {
    super.initState();
    _syncKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncOverflow();
      _ensureVisible();
    });
  }

  @override
  void didUpdateWidget(covariant ForumTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length != widget.tabs.length) {
      _syncKeys();
    }
    if (oldWidget.index != widget.index ||
        oldWidget.tabs.length != widget.tabs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncOverflow();
        _ensureVisible();
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _syncKeys() {
    _keys
      ..clear()
      ..addAll(List<GlobalKey>.generate(
          widget.tabs.length, (_) => GlobalKey(debugLabel: 'forum-tab')));
  }

  void _syncOverflow() {
    if (!mounted || !_scroll.hasClients) return;
    final bool overflow = _scroll.position.maxScrollExtent > 0.5;
    if (overflow != _overflow) {
      setState(() => _overflow = overflow);
    }
  }

  /// 选中项滚进可见范围（与官方「切页签自动滚到中间」一致）。
  void _ensureVisible() {
    if (widget.index < 0 || widget.index >= _keys.length) return;
    final BuildContext? ctx = _keys[widget.index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: TiebananaMetrics.durationBase,
      curve: TiebananaMetrics.curveStandard,
    );
  }

  Future<void> _openAll() async {
    final int? picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: TiebananaTokens.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(TiebananaMetrics.radiusXl)),
      ),
      builder: (BuildContext context) => _AllTabsSheet(
        tabs: widget.tabs,
        index: widget.index,
      ),
    );
    if (picked != null && picked != widget.index) {
      widget.onSelect(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return SizedBox(
      height: ForumTabBar.height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            TiebananaMetrics.pageGutter, 10, TiebananaMetrics.pageGutter, 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                itemCount: widget.tabs.length,
                itemBuilder: (BuildContext context, int i) => Padding(
                  padding: EdgeInsets.only(
                      right: i == widget.tabs.length - 1 ? 0 : 6),
                  child: _TabPill(
                    key: _keys[i],
                    label: widget.tabs[i].name,
                    selected: i == widget.index,
                    onTap: () => widget.onSelect(i),
                  ),
                ),
              ),
            ),
            if (_overflow) ...<Widget>[
              const SizedBox(width: 6),
              _MoreButton(onTap: _openAll, tokens: tokens),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onTap, required this.tokens});

  final VoidCallback onTap;
  final TiebananaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tokens.surfaceAlt,
      borderRadius: TiebananaMetrics.brPill,
      child: InkWell(
        borderRadius: TiebananaMetrics.brPill,
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(Icons.keyboard_arrow_down,
              size: 18, color: tokens.textSecondary),
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Material(
      color: selected ? tokens.primaryContainer : Colors.transparent,
      borderRadius: TiebananaMetrics.brPill,
      child: InkWell(
        borderRadius: TiebananaMetrics.brPill,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? tokens.onPrimaryContainer
                      : tokens.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}

/// 「全部页签」面板：当前项打勾，点选即切换。
class _AllTabsSheet extends StatelessWidget {
  const _AllTabsSheet({required this.tabs, required this.index});

  final List<TiebaForumTab> tabs;
  final int index;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: tokens.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('全部页签 · ${tabs.length} 个',
                  style: textTheme.titleSmall
                      ?.copyWith(color: tokens.textPrimary)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (int i = 0; i < tabs.length; i++)
                  _SheetTab(
                    label: tabs[i].name,
                    selected: i == index,
                    onTap: () => Navigator.of(context).pop(i),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTab extends StatelessWidget {
  const _SheetTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Material(
      color: selected ? tokens.primaryContainer : tokens.surfaceAlt,
      borderRadius: TiebananaMetrics.brCtl,
      child: InkWell(
        borderRadius: TiebananaMetrics.brCtl,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? tokens.onPrimaryContainer
                      : tokens.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}
