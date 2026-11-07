import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';
import 'package:tiebanana/shared/widgets/alert_dialog.dart';
import 'package:tiebanana/shared/content/thread_summary.dart' show Avatar;

/// 打开「切换账号」面板（概念图 `design/mockups/user.html` 的 `.sheet`）。
Future<void> showAccountSwitchSheet(BuildContext context) {
  final TiebananaTokens tokens = TiebananaTokens.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: tokens.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(TiebananaMetrics.radiusXl),
      ),
    ),
    builder: (BuildContext sheetContext) => const AccountSwitchSheet(),
  );
}

/// 账号列表面板：当前账号打勾，其余账号显示缓存的未读数；
/// 可以添加账号、管理账号（移除）与退出当前账号。
class AccountSwitchSheet extends StatefulWidget {
  const AccountSwitchSheet({super.key});

  @override
  State<AccountSwitchSheet> createState() => _AccountSwitchSheetState();
}

class _AccountSwitchSheetState extends State<AccountSwitchSheet> {
  late List<TiebananaAccount> _accounts = AccountStore.accounts;
  bool _managing = false;
  bool _busy = false;

  String? get _currentUid => AccountStore.currentUid;

  void _reload() {
    setState(() {
      _accounts = AccountStore.accounts;
      if (_accounts.isEmpty) {
        _managing = false;
      }
    });
  }

  Future<void> _switchTo(TiebananaAccount account) async {
    if (_busy || account.uid == _currentUid) {
      return;
    }
    setState(() => _busy = true);
    try {
      await AccountStore.switchTo(account.uid);
      if (!mounted) {
        return;
      }
      Provider.of<User>(context, listen: false).refreshAccount(force: true);
      Navigator.pop(context);
      Fluttertoast.showToast(msg: '已切换到 ${_displayName(account)}');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      Fluttertoast.showToast(msg: '切换失败：${_errorText(error)}');
    }
  }

  Future<void> _addAccount() async {
    if (_busy) {
      return;
    }
    // 登录会覆盖当前 cookie 仓库，先把当前账号的最新凭证落一份快照。
    await AccountStore.snapshotCurrent();
    if (!mounted) {
      return;
    }
    await Navigator.pushNamed(context, PageRouter.login, arguments: true);
    // 回到面板时刷新列表：新账号已登录时会把当前账号指过去。
    if (mounted) {
      _reload();
      Provider.of<User>(context, listen: false).refreshAccount(force: true);
    }
  }

  Future<void> _logout() async {
    if (_busy) {
      return;
    }
    final User user = Provider.of<User>(context, listen: false);
    final bool? sure = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) =>
          const TiebaAlterDialog(title: '确认退出当前账号?'),
    );
    if (sure != true || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await AccountStore.logoutCurrent();
      if (!mounted) {
        return;
      }
      user.refreshAccount(force: true);
      Navigator.pop(context);
      Fluttertoast.showToast(msg: user.isLogin ? '已退出当前账号，自动切换到其它账号' : '已退出登录');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      Fluttertoast.showToast(msg: '退出失败：${_errorText(error)}');
    }
  }

  Future<void> _remove(TiebananaAccount account) async {
    if (_busy) {
      return;
    }
    final bool isCurrent = account.uid == _currentUid;
    final bool? sure = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => TiebaAlterDialog(
        title: '移除「${_displayName(account)}」?',
        content: Text(isCurrent
            ? '移除后会自动切换到其它账号；没有其它账号时回到未登录状态。'
            : '只会删除本机保存的登录凭证，不会影响贴吧上的账号。'),
      ),
    );
    if (sure != true || !mounted) {
      return;
    }
    final User user = Provider.of<User>(context, listen: false);
    setState(() => _busy = true);
    try {
      await AccountStore.removeAccount(account.uid);
      if (!mounted) {
        return;
      }
      user.refreshAccount(force: true);
      _reload();
      setState(() => _busy = false);
      if (_accounts.isEmpty) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      Fluttertoast.showToast(msg: '移除失败：${_errorText(error)}');
    }
  }

  static String _displayName(TiebananaAccount account) {
    return account.name.isEmpty ? '账号 ${account.uid}' : account.name;
  }

  static String _errorText(Object error) {
    if (error is StateError) {
      return error.message;
    }
    return '$error';
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TiebananaMetrics.gapLg,
          10,
          TiebananaMetrics.gapLg,
          TiebananaMetrics.gapMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _handle(tokens),
            _header(tokens, textTheme),
            const SizedBox(height: TiebananaMetrics.gapSm),
            Flexible(child: _accountList(tokens, textTheme)),
            if (!_managing) ...<Widget>[
              _addAccountRow(tokens, textTheme),
              const SizedBox(height: TiebananaMetrics.gapXs),
              _footer(tokens, textTheme),
            ],
            if (_busy) ...<Widget>[
              const SizedBox(height: TiebananaMetrics.gapSm),
              LinearProgressIndicator(
                minHeight: 2,
                color: tokens.primary,
                backgroundColor: tokens.surfaceAlt,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _handle(TiebananaTokens tokens) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: tokens.lineStrong,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _header(TiebananaTokens tokens, TextTheme textTheme) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            _managing ? '管理账号' : '切换账号',
            style: textTheme.titleSmall?.copyWith(color: tokens.textPrimary),
          ),
        ),
        if (_managing)
          TextButton(
            onPressed: _busy ? null : () => setState(() => _managing = false),
            child: const Text('完成'),
          ),
      ],
    );
  }

  Widget _accountList(TiebananaTokens tokens, TextTheme textTheme) {
    if (_accounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: TiebananaMetrics.gapXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.person_add_alt_1_outlined,
                size: 30, color: tokens.textTertiary),
            const SizedBox(height: TiebananaMetrics.gapMd),
            Text('还没有其它账号',
                style: textTheme.bodyMedium
                    ?.copyWith(color: tokens.textSecondary)),
            const SizedBox(height: TiebananaMetrics.gapXs),
            Text('登录后可以在这里一键切换',
                style:
                    textTheme.bodySmall?.copyWith(color: tokens.textTertiary)),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final TiebananaAccount account in _accounts)
            _accountRow(account, tokens, textTheme),
        ],
      ),
    );
  }

  Widget _accountRow(
      TiebananaAccount account, TiebananaTokens tokens, TextTheme textTheme) {
    final bool current = account.uid == _currentUid;
    final String detail = 'ID ${account.uid}'
        '${current ? ' · 当前账号' : (account.unread > 0 ? ' · ${account.unread} 条未读' : '')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: TiebananaMetrics.gapXs),
      child: Material(
        color: current ? tokens.primaryContainer : Colors.transparent,
        borderRadius: TiebananaMetrics.brCtl,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _busy
              ? null
              : () {
                  if (_managing) {
                    _remove(account);
                  } else {
                    _switchTo(account);
                  }
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TiebananaMetrics.gapMd,
              vertical: 10,
            ),
            child: Row(
              children: <Widget>[
                Avatar(
                  imgUrl: account.portraitUrl,
                  height: 40,
                  width: 40,
                  onTap: () {},
                ),
                const SizedBox(width: TiebananaMetrics.gapSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        _displayName(account),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: current
                              ? tokens.onPrimaryContainer
                              : tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: current
                              ? tokens.onPrimaryContainer
                                  .withValues(alpha: 0.75)
                              : tokens.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_managing)
                  IconButton(
                    onPressed: _busy ? null : () => _remove(account),
                    icon: Icon(Icons.delete_outline_rounded,
                        color: tokens.danger),
                    tooltip: '移除账号',
                  )
                else if (current)
                  Icon(Icons.check_circle_rounded,
                      size: 20, color: tokens.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _addAccountRow(TiebananaTokens tokens, TextTheme textTheme) {
    return Material(
      color: Colors.transparent,
      borderRadius: TiebananaMetrics.brCtl,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _busy ? null : _addAccount,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TiebananaMetrics.gapMd,
            vertical: 12,
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.change_circle_outlined,
                  size: 18, color: tokens.primary),
              const SizedBox(width: TiebananaMetrics.gapSm),
              Text('添加账号',
                  style: textTheme.bodyLarge?.copyWith(color: tokens.primary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(TiebananaTokens tokens, TextTheme textTheme) {
    return Row(
      children: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => setState(() => _managing = true),
          child: Text('管理账号',
              style:
                  textTheme.bodyMedium?.copyWith(color: tokens.textSecondary)),
        ),
        const Spacer(),
        TextButton(
          onPressed: _busy ? null : _logout,
          child: Text('退出登录',
              style: textTheme.bodyMedium?.copyWith(color: tokens.danger)),
        ),
      ],
    );
  }
}
