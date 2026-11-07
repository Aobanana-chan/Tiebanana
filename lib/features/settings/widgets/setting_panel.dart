import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/features/account/data/account_store.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tiebanana/app/navigation/route_names.dart';
import 'package:tiebanana/features/account/widgets/account_switch_sheet.dart';
import 'package:tiebanana/shared/widgets/alert_dialog.dart';
import 'package:tiebanana/shared/widgets/setting_group.dart';

/// 「我的」页的设置分组。
///
/// 对应概念图 `design/mockups/user.html`（方向 A）的 `.sgroup`：
/// 条目按用途分成几张圆角卡片，每行是「图标 + 标题 + 右侧箭头」，
/// 方向 A 使用卡片分组表达层级，行间不画分隔线，这里给 [SettingGroup] 传 `divided: false`。
///
/// 「主题切换」「服务中心」等通用设置项集中在 `app_setting_page.dart`，
/// 这里保留「我的」页的内容入口与账号操作。
class SettingPanel extends StatelessWidget {
  const SettingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SettingGroup(
          divided: false,
          children: <Widget>[
            SettingRow(
              icon: Icons.star_outline_rounded,
              title: '我的收藏',
              showChevron: true,
              onTap: () => Navigator.pushNamed(context, PageRouter.threadStore),
            ),
            SettingRow(
              icon: Icons.history_rounded,
              title: '浏览历史',
              showChevron: true,
              onTap: () => Navigator.pushNamed(context, PageRouter.viewHistory),
            ),
            SettingRow(
              icon: Icons.settings_outlined,
              title: '设置',
              showChevron: true,
              onTap: () => Navigator.pushNamed(context, PageRouter.appSetting),
            ),
          ],
        ),
        SettingGroup(
          divided: false,
          children: <Widget>[
            SettingRow(
              icon: Icons.change_circle_outlined,
              title: '切换账号',
              showChevron: true,
              onTap: () => showAccountSwitchSheet(context),
            ),
            SettingRow(
              icon: Icons.logout_rounded,
              title: '退出登录',
              danger: true,
              onTap: () => _logout(context),
            ),
          ],
        ),
      ],
    );
  }

  /// 退出前确认一次。多账号下会先移除当前账号的凭证；还有其它账号时
  /// 自动切到第一个，没有时才回到未登录状态。
  Future<void> _logout(BuildContext context) async {
    final User user = Provider.of<User>(context, listen: false);
    final bool? sure = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) =>
          const TiebaAlterDialog(title: '确认退出当前账号?'),
    );
    if (sure != true) {
      return;
    }
    await AccountStore.logoutCurrent();
    user.refreshAccount(force: true);
  }
}
