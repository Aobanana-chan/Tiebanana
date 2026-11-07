# tieba_backend_demo

Tiebanana 的**默认后端装配包**，也是私有构建通过 `pubspec_overrides.yaml`
替换的对象。

- 应用只依赖 `createTiebaApi` 这一个入口；
- 本地演示数据与可交互的内存实现位于 `package:tieba_contract/testing.dart`
  （`DemoTiebaApi`），本包只负责装配；
- 界面测试直接引用 `tieba_contract/testing.dart`，所以 override 本包不会
  影响 `flutter test`。

演示实现的行为：

- 首页关注吧、吧页、帖子楼层、楼中楼、消息、搜索、话题、收藏、个人资料等
  都返回一套按日常场景编写的本地数据；
- 数据可交互：签到、关注、收藏、点赞、发帖、回帖、投票会更新本地状态，
  用来演示界面流程；
- 用户头像使用内置 PNG data URI，离线也能显示，不依赖第三方头像服务；
  帖子配图与吧头像仍使用公开图片地址，加载这些图片需要网络，后端本身不发起网络请求。

私有构建可以在应用根目录放 `pubspec_overrides.yaml`，把本包的依赖地址换成
`tool/private/tieba_backend_demo`（内部依赖 `packages/headless_tieba`），
不需要改界面或业务代码。
