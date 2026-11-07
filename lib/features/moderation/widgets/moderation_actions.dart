import 'package:flutter/material.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/app/navigation/app_page_route.dart';
import 'package:tiebanana/features/moderation/pages/report_page.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';

bool isOwnModerationTarget(String uid) =>
    uid.isNotEmpty &&
    uid == (AccountStore.currentUid ?? Global.profile.getString('uid'));

Future<bool> requireModerationLogin(BuildContext context) async {
  if (Global.tiebaAPI.isLogin) return true;
  final login = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
              title: const Text('请先登录'),
              content: const Text('登录后才能举报或设置拉黑范围。'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('去登录'))
              ]));
  if (login == true && context.mounted) {
    await Navigator.pushNamed(context, PageRouter.login);
  }
  return context.mounted && Global.tiebaAPI.isLogin;
}

Future<void> openReportPage(
    BuildContext context, TiebaReportTarget target) async {
  if (target.isUser && isOwnModerationTarget(target.userId)) return;
  if (!await requireModerationLogin(context) || !context.mounted) return;
  await Navigator.push(
      context, appPageRoute<void>(builder: (_) => ReportPage(target: target)));
}

Future<void> showUserModerationMenu(BuildContext context,
    {required String uid, required String name, String portrait = ''}) async {
  if (isOwnModerationTarget(uid) || (int.tryParse(uid) ?? 0) <= 0) return;
  final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: TiebananaTokens.of(context).surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(TiebananaMetrics.radiusXl))),
      builder: (context) => SafeArea(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('用户操作',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(name.isEmpty ? '用户 $uid' : name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: TiebananaTokens.of(context).textSecondary)),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.flag_outlined),
                        title: const Text('举报用户'),
                        subtitle: const Text('反馈个人资料或发布内容违规'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, 'report')),
                    const Divider(height: 1),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.block_outlined,
                            color: TiebananaTokens.of(context).danger),
                        title: Text('拉黑范围',
                            style: TextStyle(
                                color: TiebananaTokens.of(context).danger)),
                        subtitle: const Text('设置关注、互动及私信权限'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, 'block')),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消')),
                  ]))));
  if (!context.mounted) return;
  if (action == 'report') {
    await openReportPage(
        context,
        TiebaReportTarget(
            kind: TiebaReportKind.user,
            userId: uid,
            name: name,
            portrait: portrait,
            source: '用户资料'));
  } else if (action == 'block') {
    await showBlockSettings(context, uid: uid, name: name);
  }
}

Future<void> showBlockSettings(BuildContext context,
    {required String uid, required String name}) async {
  if (isOwnModerationTarget(uid) || (int.tryParse(uid) ?? 0) <= 0) return;
  if (!await requireModerationLogin(context) || !context.mounted) return;
  await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BlockDialog(uid: uid, name: name));
}

Future<void> showThreadModerationMenu(BuildContext context,
    {required TiebaReportTarget target}) async {
  final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: TiebananaTokens.of(context).surface,
      builder: (context) => SafeArea(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('帖子操作',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.flag_outlined),
                        title: const Text('举报帖子'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, 'report')),
                    if (!isOwnModerationTarget(target.userId) &&
                        (int.tryParse(target.userId) ?? 0) > 0)
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.block_outlined),
                          title: const Text('拉黑作者'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pop(context, 'block')),
                    FilledButton.tonal(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消')),
                  ]))));
  if (!context.mounted) return;
  if (action == 'report') await openReportPage(context, target);
  if (action == 'block' && context.mounted) {
    await showBlockSettings(context, uid: target.userId, name: target.name);
  }
}

class _BlockDialog extends StatefulWidget {
  const _BlockDialog({required this.uid, required this.name});
  final String uid, name;
  @override
  State<_BlockDialog> createState() => _BlockDialogState();
}

class _BlockDialogState extends State<_BlockDialog> {
  final _api = Global.tiebaAPI;
  final _account = AccountStore.currentUid;
  TiebaBlockSettings? _settings;
  bool _follow = false, _interact = false, _chat = false, _busy = false;
  String? _error;
  bool get _sameAccount =>
      identical(_api, Global.tiebaAPI) && _account == AccountStore.currentUid;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
      _settings = null;
    });
    try {
      if (!_sameAccount) throw StateError('账号已切换，请重新打开');
      final settings = await _api.getBlockSettings(widget.uid);
      if (!mounted) return;
      if (!_sameAccount) throw StateError('账号已切换，请重新打开');
      setState(() {
        _settings = settings;
        _follow = settings.follow;
        _interact = settings.interact;
        _chat = settings.chat;
      });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || _settings == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_sameAccount) throw StateError('账号已切换，请重新打开');
      await _api.setBlockSettings(
          widget.uid,
          TiebaBlockSettings(
              extended: _settings!.extended,
              follow: _settings!.extended ? _follow : _settings!.follow,
              interact: _interact,
              chat: _chat));
      if (!mounted) return;
      if (!_sameAccount) throw StateError('账号已切换，请在原账号下重新读取设置');
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('拉黑范围已保存')));
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = '$error';
          if (error is TiebaModerationUncertain) _settings = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TiebananaTokens.of(context);
    return PopScope(
        canPop: !_busy,
        child: Dialog(
            backgroundColor: tokens.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: 360,
                    maxHeight: MediaQuery.sizeOf(context).height - 80),
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                  color: tokens.danger.withValues(alpha: .12),
                                  borderRadius: TiebananaMetrics.brMd),
                              child: Icon(Icons.block_outlined,
                                  color: tokens.danger)),
                          const SizedBox(height: 18),
                          Text('拉黑范围',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: tokens.fill,
                                  borderRadius: TiebananaMetrics.brSm),
                              child: Row(children: [
                                CircleAvatar(
                                    backgroundColor: tokens.primaryContainer,
                                    child: Icon(Icons.person_outline,
                                        color: tokens.onPrimaryContainer)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(
                                          widget.name.isEmpty
                                              ? '用户 ${widget.uid}'
                                              : widget.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall),
                                      Text('ID ${widget.uid}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  color: tokens.textSecondary)),
                                    ]))
                              ])),
                          const SizedBox(height: 12),
                          Text('选择不希望收到的互动',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: tokens.textSecondary)),
                          const SizedBox(height: 12),
                          if (_busy && _settings == null)
                            const Padding(
                                padding: EdgeInsets.all(24),
                                child:
                                    Center(child: CircularProgressIndicator())),
                          if (_settings != null)
                            Container(
                                decoration: BoxDecoration(
                                    border: Border.all(color: tokens.line),
                                    borderRadius: TiebananaMetrics.brCtl),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Column(children: [
                                  if (_settings!.extended)
                                    CheckboxListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text('禁止 Ta 关注我'),
                                        value: _follow,
                                        onChanged: _busy
                                            ? null
                                            : (v) =>
                                                setState(() => _follow = v!)),
                                  CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(_settings!.extended
                                          ? '禁止 Ta 与我互动'
                                          : '禁止 Ta 评论我'),
                                      subtitle: _settings!.extended
                                          ? const Text('转发、评论、赞踩、@')
                                          : null,
                                      value: _interact,
                                      onChanged: _busy
                                          ? null
                                          : (v) =>
                                              setState(() => _interact = v!)),
                                  CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text('禁止 Ta 私信我'),
                                      value: _chat,
                                      onChanged: _busy
                                          ? null
                                          : (v) => setState(() => _chat = v!)),
                                ])),
                          if (_error != null)
                            Text(_error!,
                                style: TextStyle(color: tokens.danger)),
                          if (_settings == null && !_busy)
                            TextButton(
                                onPressed: _load, child: const Text('重新读取范围')),
                          const SizedBox(height: 22),
                          Row(children: [
                            Expanded(
                                child: FilledButton.tonal(
                                    onPressed: _busy
                                        ? null
                                        : () => Navigator.pop(context),
                                    child: const Text('取消'))),
                            const SizedBox(width: 10),
                            Expanded(
                                child: FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor: tokens.danger
                                            .withValues(alpha: .12),
                                        foregroundColor: tokens.danger),
                                    onPressed: _busy || _settings == null
                                        ? null
                                        : _save,
                                    child: Text(_busy ? '保存中…' : '保存')))
                          ]),
                        ])))));
  }
}
