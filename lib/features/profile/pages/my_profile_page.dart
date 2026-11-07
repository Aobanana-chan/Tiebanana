import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter/scheduler.dart';
import 'package:tiebanana/shared/widgets/floating_search_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/features/profile/state/profile_events.dart';
import 'package:tiebanana/features/account/state/user_state.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/shared/theme/tiebanana_metrics.dart';
import 'package:tiebanana/features/settings/widgets/setting_panel.dart';
import 'package:tiebanana/features/profile/widgets/user_card.dart';
import 'package:tiebanana/features/search/widgets/search_bar.dart';

///用户信息和设置界面
class UserPage extends StatefulWidget {
  final FloatingSearchBarController controller;
  const UserPage({super.key, required this.controller});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  /// 只拉个人资料接口（`c/u/user/profile`，cmd 303012）。
  ///
  /// 它同时带 id / 昵称 / 头像 / 签名与四项计数（关注 / 粉丝 / 关注的吧 / 帖子），
  /// 而 `getuserinfo`（`getMyInfo`）只有身份、**没有这四项计数**，
  /// uid 直接使用登录时写入的本地缓存。
  late Future<TiebaUserProfile> _profile;

  @override
  void initState() {
    super.initState();
    _profile = _loadProfile();
    profileEvents.addListener(_onProfileSaved);
  }

  void _onProfileSaved() {
    if (profileEvents.uid == Global.profile.getString('uid')) {
      final Future<TiebaUserProfile> profile = _loadProfile();
      setState(() {
        _profile = profile;
      });
    }
  }

  @override
  void dispose() {
    profileEvents.removeListener(_onProfileSaved);
    super.dispose();
  }

  Future<TiebaUserProfile> _loadProfile() async {
    final String uid = Global.profile.getString("uid") ?? "";
    if (uid.isEmpty) {
      throw Exception("缺少本地 uid");
    }
    return Global.tiebaAPI.getUserInfo(uid: uid);
  }

  /// 昵称：优先昵称（name_show），为空时退回用户名（name）。
  String _displayName(TiebaUserProfile user) => user.name;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return FutureBuilder<TiebaUserProfile>(
          future: _profile,
          builder:
              (BuildContext context, AsyncSnapshot<TiebaUserProfile> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                return const Center(
                  child: Text("初始化中..."),
                );
              case ConnectionState.active:
                return const Center(
                  child: Text("加载中..."),
                );
              default:
                final TiebaUserProfile? user = snapshot.data;
                if (user != null) {
                  SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                    Provider.of<User>(context, listen: false).name =
                        _displayName(user);
                  });
                  return Column(
                    children: [
                      SearchBar(
                        maxHeight: constraints.maxHeight,
                        barController: widget.controller,
                      ),
                      Expanded(
                          child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: (() => widget.controller.close()),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    UserCard(
                                      concernNum: user.concernNum,
                                      fansNum: user.fansNum,
                                      likeForumNum: user.likeForumNum,
                                      // 帖子 = 主题帖数（thread_num）
                                      postNum: user.postNum,
                                      portraitUrl: profileEvents.avatarUrl(
                                          user.uid, user.portraitUrl),
                                      id: user.uid,
                                      name: _displayName(user),
                                      intro: user.intro,
                                    ),
                                    const SettingPanel(),
                                    // 与概念图一致：最后一组与底栏之间留一点呼吸。
                                    const SizedBox(
                                        height: TiebananaMetrics.gapMd),
                                  ],
                                ),
                              )))
                    ],
                  );
                } else if (snapshot.hasError) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _profile = _loadProfile();
                      });
                    },
                    child: const Center(
                      child: Text("发生了错误...点击重试"),
                    ),
                  );
                }
            }
            return Container();
          },
        );
      },
    );
  }
}
