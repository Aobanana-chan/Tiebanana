# 应用架构

Tiebanana 使用 Flutter 构建界面，以 Android 为主要目标平台。应用按功能组织源码，
通过 `tieba_contract` 中的 `TiebaApi` 访问后端。账号凭证、本地数据、通知和平台交互
由应用管理，后端实现不依赖 Flutter。

## 目录

| 路径 | 职责 |
| --- | --- |
| `lib/main.dart` | 程序入口、错误处理、全局 Provider 与 MaterialApp |
| `lib/app/` | 启动、后端装配、全局服务、路由与生命周期 |
| `lib/core/` | 配置、图片缓存、日志诊断和平台能力 |
| `lib/features/` | 各功能的页面、专属部件、状态、数据与服务 |
| `lib/shared/` | 跨功能的内容渲染、媒体组件、主题、控制器与基础部件 |
| `packages/tieba_contract/` | 公开的纯 Dart 数据模型、后端接口和测试实现，Git 子模块 |
| `packages/tieba_backend_demo/` | 默认演示后端的工厂入口 |
| `packages/headless_tieba/` | 可选的私有后端实现，Git 子模块 |
| `tool/private/` | 私有构建的后端适配包与依赖覆盖模板 |
| `assets/` | 随应用打包的图标、表情、开屏图片和字标字体 |
| `android/`、`ios/` | 平台工程与平台资源 |
| `test/` | 功能、基础能力、共享组件和集成测试 |
| `docs/` | 架构说明与[图标构成资源](icon/README.md) |

## 后端边界

```text
功能页面、状态与服务
        │
        ▼
TiebaApi / 契约数据模型（tieba_contract）
        ▲
        │ 实现
        ├── 演示后端：本地数据与内存状态
        └── 私有后端：网络访问与数据转换

Global ── createTiebaApi ── lib/app/backend.dart
   └── TiebaApiHost：存储位置、键值存储、屏幕信息与回调
```

`lib/app/backend.dart` 是应用引用具体后端包的唯一位置。`Global` 创建并持有
`TiebaApi` 实例，功能代码通过契约调用业务能力，不解析后端原始响应。

公开构建使用 `packages/tieba_backend_demo`，其数据与交互实现来自
`tieba_contract/testing.dart`，不连接真实服务。私有构建通过根目录
`pubspec_overrides.yaml` 将同名包指向 `tool/private/tieba_backend_demo`。
两种构建使用相同的应用代码，装配方式见
[`tool/private/README.md`](../tool/private/README.md)。

`TiebaApiHost` 由应用提供 Cookie 存储目录、键值存储、屏幕信息以及提示、签到进度
等回调。登录失败和诊断信息在工厂装配时接入应用；Toast、通知和重新登录提示
由应用显示。契约与后端包不引用宿主源码或 Flutter。

## 启动与生命周期

`main()` 安装 Flutter、平台和 Zone 异常处理后，运行 `BootstrapApp`，同时开始初始化。

1. 初始化本地诊断与媒体播放能力。
2. `Global.init()` 读取版本和设置，初始化通知、帖子缓存与后端，刷新当前账号信息，
   打开浏览历史数据库。
3. 启动图片缓存维护，执行自动签到、网络监听、缓存清理和更新检查等生命周期钩子。
4. 初始化完成后构建主应用；开屏动画结束后移除覆盖层。

`BootState` 保存初始化结果。启动失败时显示重试和诊断导出入口。账号资料刷新失败
会保留本地凭证，不中断基础初始化。开屏首次完整播放，后续启动允许点击跳过前段动画。

`app/lifecycle/` 的 `LifeTimeCallback` 分发初始化完成、命名路由进入和首页吧列表创建
等回调。需要感知页面可见性的组件使用 `appRouteObserver`。

## 功能与状态

`lib/features/<功能>/` 按实际需要设置 `pages/`、`widgets/`、`state/`、`data/`、
`models/`、`services/`，不要求每个功能具备全部子目录。

| 功能目录 | 内容 |
| --- | --- |
| `account` | 登录、多账号、凭证管理与登录失效提示 |
| `home`、`forum`、`recommend` | 首页、吧页面、推荐与签到 |
| `thread`、`compose`、`topic` | 看帖、楼中楼、投票、发帖与话题 |
| `message`、`search` | 消息提醒与内容搜索 |
| `profile`、`media`、`moderation` | 个人资料、图片选择与上传、举报及管理操作 |
| `favorites`、`history` | 收藏与本地浏览历史 |
| `settings`、`update`、`diagnostics`、`splash` | 设置、更新、诊断与开屏 |

应用使用 Provider 注入 `User` 和 `APPSettingProvider`，分别驱动账号展示与主题设置。
页面内部使用局部 State 或功能控制器；账号变化、回复、资料更新和签到结果通过
对应的通知对象同步。`Global` 持有设置、后端、数据库、帖子缓存及通知等应用级服务，
功能数据服务可以使用这些实例。

只服务单个功能的组件留在该功能内。跨功能的正文、表情、链接和摘要放在
`shared/content/`，图片查看与视频播放放在 `shared/media/`。这些共享组件可以使用
资料预览、举报等业务能力，不是独立的通用 UI 包。`core/` 不放页面及页面专属状态。

## 导航

- `app/navigation/route_names.dart` 定义路由标识与通用参数。
- `app/navigation/app_router.dart` 注册命名路由并创建页面。
- `app/navigation/app_page_route.dart` 统一页面过渡。
- `app/navigation/link_router.dart` 处理外部链接；剪贴板帖子预览由同目录组件处理。
- 功能组件跳转时引用路由标识，不通过页面注册表访问其他页面。
- 功能专属参数放在所属功能的模型文件中，例如
  `features/compose/models/thread_compose_route_data.dart`。

## 本地数据

| 数据 | 实现与归属 |
| --- | --- |
| 应用设置、账号元数据、当前账号 | SharedPreferences；由 `Global`、设置状态与 `AccountStore` 管理 |
| 登录凭证 | 应用文档目录中的 Cookie 文件；账号切换时保存和还原各账号快照，再重建后端实例 |
| 浏览历史 | ObjectBox；`features/history/data/` 按当前账号查询和写入 |
| 帖子内容 | `ThreadCache`；文档目录 `thread_cache_v1/` 下按账号和帖子保存 JSON 快照 |
| 图片 | `core/cache/` 中的图片缓存管理与头像缓存 |
| 诊断日志 | 应用支持目录 `diagnostics/` 中的 JSON Lines 文件 |

帖子缓存保存已加载的分页、楼层与楼中楼，不主动加载整帖，也不额外下载媒体。
普通缓存自最近一次成功获取内容起保留 24 小时；开启长期缓存收藏帖时，收藏内容长期
保留。帖子页先显示缓存再获取在线内容，更新按内容 ID 合并；读取失败时保留现有内容，
由用户手动刷新恢复请求。

ObjectBox 模型位于 `lib/objectbox-model.json`，字段与实体的 UID 需要保持稳定。
`lib/objectbox.g.dart` 由 `dart run build_runner build` 生成，不纳入版本控制。

诊断模块记录异常与受控的内容结构信息，字段经过白名单和脱敏处理，不保存凭证或
完整业务响应。日志单文件上限 2 MiB，总量上限 20 MiB，保留 7 天。用户手动导出或分享
诊断 ZIP，不自动上传；导出内容为环境清单和日志，不包含数据库或 Cookie 文件。

## 主题与资源

`shared/theme/` 以 `TiebananaSeed` 为输入，生成明暗调色板和 `ThemeData`。
`TiebananaTokens` 提供语义色，`TiebananaMetrics` 定义间距、圆角和尺寸，
`tiebanana_typography.dart` 结合用户字号设置生成字阶。页面通过主题取得颜色与文字样式。

`assets/` 仅存放运行时资源，图标路径使用小写 `assets/icon/`。Android 与 iOS
启动器图标保存在各自的平台资源目录。图标的构成素材、字体许可证和生成脚本位于
[`docs/icon/`](icon/README.md)，不参与应用运行时资源加载。

## 开发与测试

公开构建只需初始化契约子模块：

```sh
git submodule update --init packages/tieba_contract
flutter pub get
dart run build_runner build
flutter test
```

私有构建还需要对应子模块的读取权限和依赖覆盖配置。界面测试直接使用
`tieba_contract/testing.dart`，不经过可被覆盖的后端包。

`test/features/`、`test/core/`、`test/shared/` 对应源码归属；`test/architecture/`
检查颜色、字号与平台权限等约束；`test/integration/` 覆盖应用集成行为，
`test/support/` 提供共享夹具。浏览历史测试需要本机可加载 ObjectBox 原生库，
Windows 上需准备 `objectbox.dll`。
