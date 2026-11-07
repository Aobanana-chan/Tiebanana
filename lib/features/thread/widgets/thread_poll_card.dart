import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 投票卡片。
///
/// 视觉对齐官方“蓝方 / 红方”阵营：
/// - 恰好两个选项（或 `two_options` 正反方）时，用左蓝右红的对决布局，
///   中间一个 VS 徽标，双方各自展示选项、票数占比与进度。
/// - 三个及以上选项继续用纵向列表。
/// - 数据缺失（`poll == null` 或没有选项）时显示一行文字占位。
///
/// [onVote] 非空时允许选择并提交；为空时只读，按钮显示“暂不支持投票”。
class ThreadPollCard extends StatefulWidget {
  const ThreadPollCard({
    super.key,
    this.poll,
    this.compact = false,
    this.onVote,
  });

  final TiebaPoll? poll;
  final bool compact;

  /// 提交投票。参数为选中的选项 ID；成功后调用方负责刷新帖子页。
  final Future<void> Function(Set<int> optionIds)? onVote;

  @override
  State<ThreadPollCard> createState() => _ThreadPollCardState();
}

class _ThreadPollCardState extends State<ThreadPollCard> {
  final Set<int> _selected = <int>{};
  bool _submitting = false;

  bool get _compact => widget.compact;
  TiebaPoll? get _poll => widget.poll;

  @override
  Widget build(BuildContext context) {
    final t = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final p = _poll;
    final ended = p?.endedAt(DateTime.now());
    final result = p?.hasVoted == true || ended == true;
    // 红蓝阵营：优先 two_options（正反方），否则恰好两个选项时视为蓝方 / 红方。
    final List<TiebaPollOption>? camps = p == null ? null : _camps(p);
    final bool details = p != null && (p.options.isNotEmpty || camps != null);
    // 选项数与服务端声明一致时才计算占比；正反方使用各自阵营的计数。
    final bool optionsComplete = p == null ||
        p.optionCount == null ||
        p.optionCount == p.options.length;
    final bool campsUseOptions = p != null && p.options.length == 2;
    final List<int>? campPercentages = camps != null &&
            result &&
            (campsUseOptions ? optionsComplete : true)
        ? _percentagesOf(camps, p!.totalVotes)
        : null;
    final List<int>? listPercentages = details && result && optionsComplete
        ? _percentagesOf(p.options, p.totalVotes)
        : null;
    final double radius = _compact ? TiebananaMetrics.radiusCtl : 16;
    final String status = ended == true
        ? '已结束'
        : p?.hasVoted == true
            ? '已参与'
            : '进行中';
    final bool canVote = details && !result && widget.onVote != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_compact ? 12 : 14),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ── 标题栏 ──────────────────────────────────────────────
          Row(
            children: <Widget>[
              Icon(Icons.how_to_vote_outlined, size: 18, color: t.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  details ? '投票' : '投票内容',
                  style: textTheme.labelMedium?.copyWith(
                    color: t.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (details)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.fill,
                    borderRadius:
                        BorderRadius.circular(TiebananaMetrics.radiusXs),
                  ),
                  child: Text(
                    status,
                    style: textTheme.labelSmall?.copyWith(
                      color: ended == true ? t.textTertiary : t.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          // ── 数据缺失：纯文字占位，不渲染图片 ────────────────────
          if (!details) ...[
            const SizedBox(height: TiebananaMetrics.gapSm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Text(
                    '包含投票，暂未获取到详情',
                    style: textTheme.bodySmall?.copyWith(
                      color: t.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: TiebananaMetrics.gapSm),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.fill,
                    borderRadius:
                        BorderRadius.circular(TiebananaMetrics.radiusXs),
                  ),
                  child: Text(
                    '查看',
                    style: textTheme.labelSmall?.copyWith(
                      color: t.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // ── 标题 ─────────────────────────────────────────────
            if (p.title.trim().isNotEmpty) ...[
              SizedBox(height: _compact ? 10 : 14),
              Text(
                p.title,
                style: textTheme.bodyMedium?.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
            // ── 单选 / 多选 + 提示 ───────────────────────────────
            if (p.multiple != null || p.optionCount != null) ...[
              const SizedBox(height: TiebananaMetrics.gapXs),
              Text(
                _metaLine(p, camps != null),
                style: textTheme.bodySmall?.copyWith(color: t.textTertiary),
              ),
            ],
            SizedBox(height: _compact ? 10 : 14),

            // ── 红蓝阵营 / 普通列表 ──────────────────────────────
            if (camps != null)
              _campDuel(context, p, camps, result, campPercentages, canVote)
            else
              for (var i = 0; i < p.options.length; i++) ...[
                if (i > 0) const SizedBox(height: TiebananaMetrics.gapSm),
                _option(context, p, p.options[i], result, listPercentages?[i],
                    canVote),
              ],

            if (p.optionCount != null && p.optionCount! > p.options.length) ...[
              const SizedBox(height: TiebananaMetrics.gapSm),
              Text(
                '部分选项暂未返回',
                style: textTheme.bodySmall?.copyWith(color: t.textTertiary),
              ),
            ],

            // ── 投票按钮 ─────────────────────────────────────────
            if (!result) ...[
              const SizedBox(height: TiebananaMetrics.gapMd),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canVote && _selected.isNotEmpty && !_submitting
                      ? () => _submit(p)
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(TiebananaMetrics.radiusSm),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          canVote
                              ? (_selected.length > 1
                                  ? '投票（${_selected.length}）'
                                  : '投票')
                              : '暂不支持投票',
                        ),
                ),
              ),
            ],

            // ── 已投票提示 ───────────────────────────────────────
            if (p.hasVoted == true) ...[
              const SizedBox(height: TiebananaMetrics.gapMd),
              Row(
                children: <Widget>[
                  Icon(Icons.check_circle_outline,
                      size: 15, color: t.primary),
                  const SizedBox(width: 5),
                  Text(
                    '你已投票',
                    style: textTheme.bodySmall?.copyWith(
                      color: t.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            // ── 统计 ─────────────────────────────────────────────
            if (p.participantCount != null || p.totalVotes != null) ...[
              const SizedBox(height: TiebananaMetrics.gapSm),
              Text(
                <String>[
                  if (p.participantCount != null)
                    '${p.participantCount} 人参与',
                  if (p.totalVotes != null) '${p.totalVotes} 票',
                ].join(' · '),
                style: textTheme.bodySmall?.copyWith(color: t.textTertiary),
              ),
            ],
            if (p.endTime != null && p.endTime! > 0) ...[
              const SizedBox(height: TiebananaMetrics.gapXXs),
              Text(
                _deadline(p.endTime!),
                style: textTheme.bodySmall?.copyWith(color: t.textTertiary),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _submit(TiebaPoll p) async {
    if (_submitting || _selected.isEmpty || widget.onVote == null) return;
    setState(() => _submitting = true);
    try {
      await widget.onVote!(Set<int>.unmodifiable(_selected));
      if (!mounted) return;
      setState(() {
        _selected.clear();
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  void _tapOption(TiebaPoll p, TiebaPollOption option, bool canVote) {
    if (!canVote || option.id == null) return;
    final int id = option.id!;
    setState(() {
      if (p.multiple == true) {
        if (!_selected.remove(id)) {
          _selected.add(id);
        }
      } else {
        _selected
          ..clear()
          ..add(id);
      }
    });
  }

  String _metaLine(TiebaPoll p, bool camps) {
    final String mode = p.multiple == true ? '多选' : '单选';
    if (camps) {
      return '$mode · 蓝方与红方对决';
    }
    return mode;
  }

  /// 只有恰好两方时才走红蓝阵营。
  ///
  /// 官方有两条表示：`options` 与 `two_options`（pros/cons）。优先用
  /// `options`（票数口径和 `participantCount` 对得上），缺失时才退回正反方。
  List<TiebaPollOption>? _camps(TiebaPoll p) {
    if (p.options.length == 2) {
      return <TiebaPollOption>[p.options[0], p.options[1]];
    }
    final TiebaPollOption? pros = p.pros;
    final TiebaPollOption? cons = p.cons;
    if (pros != null &&
        cons != null &&
        (pros.text.trim().isNotEmpty || pros.imageUrl.trim().isNotEmpty) &&
        (cons.text.trim().isNotEmpty || cons.imageUrl.trim().isNotEmpty)) {
      return <TiebaPollOption>[pros, cons];
    }
    return null;
  }

  /// 左蓝右红的对决区；窄屏（分屏 / 大字号）下自动改为上下排布。
  Widget _campDuel(
    BuildContext context,
    TiebaPoll p,
    List<TiebaPollOption> camps,
    bool result,
    List<int>? percentages,
    bool canVote,
  ) {
    final t = TiebananaTokens.of(context);
    final TiebaPollOption left = camps[0];
    final TiebaPollOption right = camps[1];

    Widget card(String label, Color accent, Color container, Color on,
        TiebaPollOption option, int? percentage, int index) {
      final bool selected = _selected.contains(option.id) ||
          _isVotedSelection(p, option);
      return _CampCard(
        sideLabel: label,
        accent: accent,
        container: container,
        onContainer: on,
        option: option,
        result: result,
        percentage: percentage,
        totalVotes: p.totalVotes,
        selected: selected,
        onTap: canVote ? () => _tapOption(p, option, canVote) : null,
      );
    }

    final Widget leftCard =
        card('蓝方', t.pollBlue, t.pollBlueContainer, t.pollBlueOnContainer,
            left, percentages?[0], 0);
    final Widget rightCard =
        card('红方', t.pollRed, t.pollRedContainer, t.pollRedOnContainer,
            right, percentages?[1], 1);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // 左右并排至少需要 ~260 逻辑像素；空间不足时改为上下排布，
        // 适配长选项和大字号。常见手机内容宽度约 286，仍走并排。
        if (constraints.maxWidth < 260) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              leftCard,
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Center(child: _VsBadge(tokens: t)),
              ),
              rightCard,
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: leftCard),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Center(child: _VsBadge(tokens: t)),
              ),
              Expanded(child: rightCard),
            ],
          ),
        );
      },
    );
  }

  bool _isVotedSelection(TiebaPoll p, TiebaPollOption option) {
    if (p.hasVoted != true || option.id == null) {
      return false;
    }
    if (p.selectedIds.contains(option.id)) {
      return true;
    }
    return option.hasVoted == true;
  }

  /// 普通（3 个及以上选项）列表项。
  Widget _option(
    BuildContext context,
    TiebaPoll p,
    TiebaPollOption option,
    bool result,
    int? percentage,
    bool canVote,
  ) {
    final t = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool selected =
        _selected.contains(option.id) || _isVotedSelection(p, option);
    final bool validImage = _validImageUrl(option.imageUrl);
    final double? ratio =
        percentage != null && result ? _ratio(option.votes, p.totalVotes) : null;
    final BorderRadius shape = BorderRadius.circular(TiebananaMetrics.radiusSm);

    final Widget body = Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected ? t.primaryContainer : t.surface,
        border: Border.all(
          color: selected ? t.primary.withValues(alpha: .4) : t.line,
        ),
        borderRadius: shape,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (validImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(TiebananaMetrics.radiusXs),
                  child: Image.network(
                    option.imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: t.fill,
                        borderRadius:
                            BorderRadius.circular(TiebananaMetrics.radiusXs),
                      ),
                      child: Icon(Icons.image_not_supported_outlined,
                          size: 18, color: t.textTertiary),
                    ),
                  ),
                ),
                const SizedBox(width: TiebananaMetrics.gapSm),
              ],
              Expanded(
                child: Text(
                  option.text.isNotEmpty ? option.text : '选项',
                  style: textTheme.bodySmall?.copyWith(
                    color: selected ? t.onPrimaryContainer : t.textPrimary,
                    height: 1.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 5),
                Icon(Icons.check_circle_rounded, size: 16, color: t.primary),
              ],
            ],
          ),
          if (ratio != null) ...[
            const SizedBox(height: TiebananaMetrics.gapSm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                backgroundColor: t.fill,
                color: selected ? t.primary : t.primary.withValues(alpha: .35),
              ),
            ),
          ],
          if (result && option.votes != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${option.votes} 票${percentage != null ? ' · $percentage%' : ''}',
                style: textTheme.bodySmall?.copyWith(
                  color: selected ? t.onPrimaryContainer : t.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Semantics(
      selected: selected,
      button: canVote,
      child: canVote
          ? Material(
              color: Colors.transparent,
              borderRadius: shape,
              child: InkWell(
                borderRadius: shape,
                onTap: () => _tapOption(p, option, canVote),
                child: body,
              ),
            )
          : body,
    );
  }

  static bool _validImageUrl(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) return false;
    final Uri? uri = Uri.tryParse(value);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  static double? _ratio(int? votes, int? total) {
    if (votes == null || total == null || total <= 0) return null;
    return (votes / total).clamp(0.0, 1.0);
  }

  String _deadline(int seconds) {
    final d = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year} 年 ${d.month} 月 ${d.day} 日 ${two(d.hour)}:${two(d.minute)} 截止';
  }

  /// 票数占比；总数有效且与选项票数之和一致时返回结果，否则返回 null。
  List<int>? _percentagesOf(List<TiebaPollOption> options, int? total) {
    if (total == null ||
        total <= 0 ||
        options.any((o) => o.votes == null || o.votes! < 0) ||
        options.fold<int>(0, (sum, o) => sum + o.votes!) != total) {
      return null;
    }
    final exact = options.map((o) => o.votes! / total * 100).toList();
    final rounded = exact.map((n) => n.floor()).toList();
    final order = List.generate(exact.length, (i) => i)
      ..sort((a, b) {
        final compare =
            (exact[b] - rounded[b]).compareTo(exact[a] - rounded[a]);
        return compare == 0 ? a.compareTo(b) : compare;
      });
    final remainder = 100 - rounded.fold<int>(0, (sum, n) => sum + n);
    for (var i = 0; i < remainder; i++) {
      rounded[order[i]]++;
    }
    return rounded;
  }
}

/// 红蓝阵营卡片。
class _CampCard extends StatelessWidget {
  const _CampCard({
    required this.sideLabel,
    required this.accent,
    required this.container,
    required this.onContainer,
    required this.option,
    required this.result,
    required this.percentage,
    required this.totalVotes,
    required this.selected,
    this.onTap,
  });

  final String sideLabel;
  final Color accent;
  final Color container;
  final Color onContainer;
  final TiebaPollOption option;
  final bool result;
  final int? percentage;
  final int? totalVotes;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool validImage =
        _ThreadPollCardState._validImageUrl(option.imageUrl);
    final double? ratio =
        _ThreadPollCardState._ratio(option.votes, totalVotes);
    final BorderRadius shape =
        BorderRadius.circular(TiebananaMetrics.radiusSm);

    final Widget body = Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: container,
        borderRadius: shape,
        border: Border.all(
          color: selected ? accent : accent.withValues(alpha: .3),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                sideLabel,
                style: textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (selected)
                Icon(Icons.check_circle_rounded, size: 15, color: accent),
            ],
          ),
          if (validImage) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(TiebananaMetrics.radiusXs),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  option.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => ColoredBox(
                    color: accent.withValues(alpha: .08),
                    child: Icon(Icons.image_not_supported_outlined,
                        size: 18, color: accent),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            option.text.isNotEmpty ? option.text : '选项',
            style: textTheme.bodySmall?.copyWith(
              color: onContainer,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (result && ratio != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                backgroundColor: accent.withValues(alpha: .16),
                color: accent,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 6,
              runSpacing: 2,
              children: <Widget>[
                if (percentage != null)
                  Text(
                    '$percentage%',
                    style: textTheme.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                if (option.votes != null)
                  Text(
                    '${option.votes} 票',
                    style: textTheme.labelSmall?.copyWith(
                      color: accent.withValues(alpha: .8),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    return Semantics(
      selected: selected,
      button: onTap != null,
      child: onTap == null
          ? body
          : Material(
              color: Colors.transparent,
              borderRadius: shape,
              child: InkWell(
                borderRadius: shape,
                onTap: onTap,
                child: body,
              ),
            ),
    );
  }
}

/// 中间的 VS 徽标。
class _VsBadge extends StatelessWidget {
  const _VsBadge({required this.tokens});

  final TiebananaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.fill,
        shape: BoxShape.circle,
        border: Border.all(color: tokens.line),
      ),
      child: Text(
        'VS',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tokens.textTertiary,
              fontWeight: FontWeight.w800,
              height: 1,
              fontSize: 10,
            ),
      ),
    );
  }
}
